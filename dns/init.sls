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

/etc/named.conf:
  file.managed:
    - source: salt://dns/named.conf.jinja
    - template: jinja
    - user: root
    - group: named
    - mode: 640
    - require:
      - pkg: named

/var/named/named.auto.dot:
  file.managed:
    - source: salt://dns/named.auto.dot.jinja
    - template: jinja
    - user: named
    - group: named
    - mode: 644
    - require:
      - pkg: named
