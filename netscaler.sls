{%- macro netscaler(role) %}
{%- set minions = salt["mine.get"]("G@roles:"+role, "network.ip_addrs", "compound") %}
{%- set vservers = salt['pillar.get']('netscaler:roles:'+role, {}) %}
{%- for vs, vs_attrs in vservers.iteritems() %}

{{ vs }}:
  netscaler.present:
  - ip: {{ vs_attrs.get('ip', '0.0.0.0') }}
  {%- if 'sslcert' in vs_attrs.keys() %}
    {%- if vs_attrs.get('type', 'SSL')|upper != 'SSL' or vs_attrs.get('port', 443) != 443 %}
      {{ salt['This should never happen']('This text is here to invalidate the state!') }}
    {% endif %}
  - port: 443
  - type: 'SSL'
  - sslcert: {{ vs_attrs['sslcert'] }}
  {%- else %}
  - port: {{ vs_attrs.get('port', '80') }}
  - type: {{ vs_attrs.get('type', 'HTTP') }}
  {%- endif %}

  {%- if 'servicegroups' in vs_attrs.keys() %}
  - servicegroup:
    {%- if vs_attrs['servicegroups'] is string %}
      {%- do vs_attrs.update({'servicegroups':{vs_attrs['servicegroups']:{}}}) %}
    {%- endif %}
    {%- for sg, sg_attrs in vs_attrs['servicegroups'].iteritems() %}
      - name: {{ sg }}
        type: {{ sg_attrs.get('type', 'HTTP') }}
        servers:
      {%- for minion_id, ips in minions.iteritems() %}
        {{ minion_id }}:
            ip: {{ ips[0] }}
            port: {{ sg_attrs.get('port', vs_attrs.get('port', '80')) }}
            status: enabled
      {%- endfor %} {# minions #}
    {%- endfor %} {# vs_attrs #}
  {%- endif %} {# servicegroups #}

{%- endfor %} {# vservers #}
{%- endmacro %}



{{ netscaler('api') }}