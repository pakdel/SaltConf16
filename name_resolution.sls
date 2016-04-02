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
