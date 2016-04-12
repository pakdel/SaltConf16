/etc/resolv.conf:
  file.managed:
    - contents: |
                ; Managed by Salt, please do NOT edit
                search auto.dot
{%- for ip_addrs in salt['mine.get']('roles:dns', 'network.ip_addrs', 'grain').values() %}
{#- Assuming one IP per DNS server #}
                nameserver {{ ip_addrs[0] }}
{%- endfor %}

    - user: root
    - group: root
    - mode: 644

schedule_salt-minion_restart:
  cmd.wait:
    - name: nohup /bin/sh -c 'sleep 3; salt-call --local service.stop salt-minion; sleep 3; killall salt-minion; sleep 3; salt-call --local service.restart salt-minion; sleep 3; salt-call --local service.start salt-minion' >>/var/log/salt/minion 2>&1 & echo Salt-Minion Restart Scheduled ...
    - watch:
      - file: /etc/resolv.conf
    - order: last

# "helper" module has a part that reinitializes libc.so.6 as following:
# ctypes.CDLL('libc.so.6').__res_init(None)
sync_modules:
  module.wait:
    - name: saltutil.sync_modules
    - watch:
      - file: /etc/resolv.conf
reload_resolv_conf:
  module.wait:
    - name: helper.reload_resolv_conf
    - watch:
      - file: /etc/resolv.conf
      - module: sync_modules

/tmp/test:
  file.managed:
    - source: http://api.auto.dot/test
    - source_hash: md5=8ddd8be4b179a529afa5f2ffae4b9858
    - order: last
