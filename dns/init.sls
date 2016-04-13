include:
  - name_resolution

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
