base:
  '* not G@os:Windows':
    - match: compound
    - name_resolution
  'roles:dns':
    - match: grains
    - dns
  'roles:api':
    - match: grains
    - api
