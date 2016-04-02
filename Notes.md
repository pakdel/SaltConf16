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
