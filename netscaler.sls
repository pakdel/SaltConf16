vip.api.auto.dot:
  netscaler.present:
  - ip: 172.31.0.201
  - port: 80
  - type: HTTP

  - servicegroup:
    - name: sg.api.auto.dot
      type: HTTP
      servers:
      {#- Assuming one IP per server #}
      {%- for minion_id, ip_addrs in salt['mine.get']('roles:api', 'network.ip_addrs', 'grain').iteritems() %}
        {{ minion_id }}:
          ip: {{ ip_addrs[0] }}
          port: 80
          status: enabled
      {%- endfor %}
