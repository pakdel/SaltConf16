API elb:
  boto_elb.present:
    - name: api
    - region: us-east-1
    - security_groups:
      - sg-f12d2889
    - availability_zones:
      - us-east-1a
      - us-east-1b
      - us-east-1d
      - us-east-1e
    - listeners:
      - elb_port: 80
        instance_port: 80
        elb_protocol: HTTP
        instance_protocol: HTTP
    - health_check:
        target: 'HTTP:80/test'
    - cnames:
      - name: api.auto.dot.
        zone: auto.dot.

API instances in elb:
  boto_elb.register_instances:
    - name: api
    - instances:
{%- for api_instance_grains in salt['mine.get']('roles:api', 'grains.item', 'grain').values() %}
      - {{ api_instance_grains['ec2_instance_id'] }}
{%- endfor %}
