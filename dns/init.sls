/etc/dhcp/dhclient-enter-hooks:
  file.managed:
    - contents: |
                #######################################
                # Managed by Salt, please do NOT edit #
                #######################################
                # Creating /etc/named.forwarders to be used by Bind, if needed
                echo "    forwarders { ${new_domain_name_servers// /;}; };" >/etc/named.forwarders

    - template: jinja
    - user: root
    - group: root
    - mode: 755

renew_dhcp:
  cmd.wait:
    - name: dhclient -r && dhclient
    - watch:
      - file: /etc/dhcp/dhclient-enter-hooks

named:
  pkg.installed:
    - name: bind
  service.running:
    - enable: True
    - require:
      - pkg: named
    - watch:
      - file: /etc/named.conf
      - file: /var/named/named.auto.dot
      - file: /etc/dhcp/dhclient-enter-hooks
      - cmd: renew_dhcp

/etc/named.conf:
  file.managed:
    - source: salt://dns/named.conf.jinja
    - template: jinja
    - user: root
    - group: named
    - mode: 640
    - require:
      - pkg: named

set_dns_sequence_grain:
  module.run:
    - name: grains.setval
    - key: 'dns_sequence'
    - val: {{ salt['helper.dns_sequence']() }}
    - prereq:
      - file: /var/named/named.auto.dot

/var/named/named.auto.dot:
  file.managed:
    - source: salt://dns/named.auto.dot.jinja
    - template: jinja
    - user: named
    - group: named
    - mode: 644
    - require:
      - pkg: named
