apache:
  pkg.installed:
    - name: httpd
  service.running:
    - name: httpd
    - enable: True
    - require:
      - pkg: httpd
    - watch:
      - file: /var/www/html/test

/var/www/html/test:
  file.managed:
    - contents: |
                Hello World!

    - user: root
    - group: root
    - mode: 644
