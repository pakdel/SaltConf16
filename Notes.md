# V. 1

- We have a legacy API, let's call it 'api'
```
salt minion state.sls api
salt minion grains.get fqdn_ip4
curl http://172.31.47.167/test
```

- In order to give it a name, we need a DNS
-- Let's call this domain `auto.dot`
```
salt minion grains.setval roles '["dns"]'
salt minion state.sls dns
salt minion cmd.run 'dig @127.0.0.1 test.auto.dot'
salt minion cmd.run 'dig test.auto.dot'
salt minion cmd.run 'cat /etc/resolv.conf'
```

- resolv.conf
```
salt minion grains.get roles
salt minion state.sls name_resolution
salt minion cmd.run 'dig test.auto.dot'
```
- `api.auto.dot`
```
salt minion grains.setval roles '["dns", "api"]'
salt minion state.sls dns
## Something is wrong, because something else needed to change
salt minion cmd.run 'dig api.auto.dot'
salt minion state.sls test
```
[DNS: changes in /etc/resolv.conf aren't picked up](https://bugzilla.mozilla.org/show_bug.cgi?id=214538) /
[libc caches resolv.conf forever](https://sourceware.org/bugzilla/show_bug.cgi?id=3675)



# V. 2
## V. 2.1
- Restarting Salt Minion not only will not help with the rest of state execution,
but also it will break long states (like highstate)
```
salt minion cmd.run "nohup /bin/sh -c 'sleep 3; salt-call --local service.stop salt-minion; sleep 3; killall salt-minion; sleep 3; salt-call --local service.restart salt-minion; sleep 3; salt-call --local service.start salt-minion' >>/var/log/salt/minion 2>&1 & echo Salt-Minion Restart Scheduled ..."
```

## V. 2.2
- Reloading resolve.conf will not help with next state executions

## V. 2.3
- We need both
```
# Restarted networking on the minion to revert back resolv.conf
salt minion state.sls name_resolution
salt minion state.sls test
```



# V. 3
- But "serial" is not updated!
`salt minion state.sls dns`

## V.3.1
- Using time in seconds
```
salt minion saltutil.sync_modules
salt minion state.sls dns
```

## V.3.2
- Let's set a grain
```
salt minion state.sls dns
```
- It failed!
  - Running Salt Minion in Debug mode:
```
salt-minion -l debug

[DEBUG   ] In saltenv 'base', ** considering ** path u'/var/cache/salt/minion/files/base/dns/named.auto.dot.jinja' to resolve u'salt://dns/named.auto.dot.jinja'
```
  - Failed while ** considering **
    Because of the prerequisite, it needs to evaluate the Jinja to see if it needs to set the grains, which will faild during first execution.

## V.3.3
- dns_sequence grain needs a default

## V.3.4
- What if we have more than one DNS?
- Austritch solution:
    dns_sequence => time.time() / 100


*Note*: Beware of `RuntimeError: maximum recursion depth exceeded` error!



# V. 4
- What about repo.saltstack.com, or the Virtual Router of your CloudStack, or the DNS provided by the DHCP of AWS?
    - Well, we already have repo.saltstack.com covered.

## V.4.1
- Put it in resolv.conf:
Lets put it in the [interface config file](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s1-networkscripts-interfaces.html) using `PEERDNS`
    - But we cannot get the DNS provided by DHCP in this file
- Lets use DHCP Client Scripts as in [man 8 dhclient-script](http://linux.die.net/man/8/dhclient-script)
    - On after defining the make_resolv_conf function, the client script checks for the presence of an executable `/etc/dhcp/dhclient-enter-hooks` script, and if present, it invokes the script inline
    - Going to update values of `new_domain_name_servers` and `new_domain_name_servers` variables
    - And it needs a reload / restart

```
salt minion state.sls name_resolution
salt minion cmd.run 'nslookup ip-172-31-32-50.ec2.internal'
```

The default behavior for resolv.conf and the resolver is to try the servers in the order listed. The resolver will only try the next nameserver if the first nameserver times out. The [resolv.conf manpage](http://linux.die.net/man/5/resolv.conf) says "The algorithm used is to try a name server, and if the query times out, try the next, until out of name servers, then repeat trying all the name servers until a maximum number of retries are made.". Even if `rotate` is used, it will not solve the issue.

## V.4.2
- Using DHCP Client Scripts to set up DNS forwarder(s)

```
salt minion cmd.run 'rm -f /etc/dhcp/dhclient-enter-hooks'
salt minion cmd.run 'dhclient -r && dhclient'
salt minion state.sls name_resolution

salt minion state.sls dns
```

- But on the DNS itself, `/etc/resolv.conf` is managed by DHCP and Salt
    - persian expression: two kings do not fit in the same kingdom (cannot rule the same kingdom)

## V.4.3
- Using DHCP Client Scripts to only set up DNS forwarder(s), but not the `/etc/resolv.conf` itself

```
salt minion cmd.run 'rm -f /etc/dhcp/dhclient-enter-hooks'
salt minion cmd.run 'dhclient -r && dhclient'
salt minion state.sls name_resolution

salt minion state.sls dns
```



# V. 5
- We better have a LoadBalancer when deploying a new version of this API
- Create the Route53 Zone (`auto.dot.`)

## V.5.1
- Create the ELB
- Add the ELB to `auto.dot.` as a Route53 Record Set

## V.5.2
- Add instances to the ELB
    - Do not forget to put `ec2_instance_id` in `mine_functions:grains.item`
    - You can also use [salt-contrib/grains/ec2_info.py](https://github.com/saltstack/salt-contrib/blob/master/grains/ec2_info.py) for EC2 pillars

```
salt minion saltutil.sync_grains
salt minion grains.get ec2_instance_id
salt minion mine.update

salt minion state.sls elb
```
