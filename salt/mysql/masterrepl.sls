{% for user, stuff in salt['pillar.get']('replication:users').iteritems() %}
{{ user }}:
  mysql_user.present:
    - host: {{ salt['pillar.get']('replication:host', 'localhost') }}
    - password: "{{ salt['grains.get_or_set_hash']('%s:password'|format(user)) }}"
    - port: {{ salt['pillar.get']('replication:port', '3306') }}
    - &connections
        - connection_user: root
        - connection_pass: "{{ salt['config.get']('mysql:server:root_password', '') }}"
        - connection_host: {{ salt['config.get']('mysql:server:host', 'localhost') }}
    - <<: *connections
    - requires:
      - service: mysql

{{ user }}_replication:
  mysql_grants:
    - present
    - grant: {{ stuff['grants'] }}
    - database: "*.*"
    - user: {{ user }}
    - host: {{ salt['pillar.get']('replication:host', 'localhost') }}
    - <<: *connections
    - requires:
      - service: mysql
{% endfor %}
