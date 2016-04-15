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
