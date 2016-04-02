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
-- Running Salt Minion in Debug mode:
```
salt-minion -l debug

[DEBUG   ] In saltenv 'base', ** considering ** path u'/var/cache/salt/minion/files/base/dns/named.auto.dot.jinja' to resolve u'salt://dns/named.auto.dot.jinja'
```
--- Failed while ** considering **
Because of the prerequisite, it needs to evaluate the Jinja to see if it needs to set the grains, which will faild during first execution.
