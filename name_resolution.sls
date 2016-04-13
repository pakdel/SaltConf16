/etc/dhcp/dhclient-enter-hooks:
  file.managed:
    - contents: |
                #######################################
                # Managed by Salt, please do NOT edit #
                #######################################
                # Prepend the DNS of environment to the list of nameservers
                {#- Assuming one IP per DNS server #}
                new_domain_name_servers="{% for ip_addrs in salt['mine.get']('roles:dns', 'network.ip_addrs', 'grain').values() %}{{ ip_addrs[0] }} {% endfor %}${new_domain_name_servers}"
                new_domain_name="auto.dot"
                {% if 'dns' in grains['roles'] %}
                # Creating /etc/named.forwarders to be used by Bind, if needed
                echo "    forwarders { ${new_domain_name_servers// /;}; };" >/etc/named.forwarders
                {% endif %}

    - template: jinja
    - user: root
    - group: root
    - mode: 755

renew_dhcp:
  cmd.wait:
    - name: dhclient -r && dhclient
    - watch:
      - file: /etc/dhcp/dhclient-enter-hooks

schedule_salt-minion_restart:
  cmd.wait:
    - name: nohup /bin/sh -c 'sleep 3; salt-call --local service.stop salt-minion; sleep 3; killall salt-minion; sleep 3; salt-call --local service.restart salt-minion; sleep 3; salt-call --local service.start salt-minion' >>/var/log/salt/minion 2>&1 & echo Salt-Minion Restart Scheduled ...
    - watch:
      - cmd: renew_dhcp
    - order: last

# "helper" module has a part that reinitializes libc.so.6 as following:
# ctypes.CDLL('libc.so.6').__res_init(None)
sync_modules:
  module.wait:
    - name: saltutil.sync_modules
    - watch:
      - cmd: renew_dhcp
reload_resolv_conf:
  module.wait:
    - name: helper.reload_resolv_conf
    - watch:
      - cmd: renew_dhcp
      - module: sync_modules

/tmp/test:
  file.managed:
    - source: http://api.auto.dot/test
    - source_hash: md5=8ddd8be4b179a529afa5f2ffae4b9858
    - order: last
