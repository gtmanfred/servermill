{% for user, stuff in salt['pillar.get']('websites:blog.manfred.io:users').iteritems() %}
{{stuff['database']}}:
  mysql_database.present:
    - name: {{stuff['database']}}
    - &connections
        - connection_user: root
        - connection_pass: "{{ salt['config.get']('mysql:server:root_password', '') }}"
        - connection_host: {{ salt['config.get']('mysql:server:host', 'localhost') }}
    - <<: *connections
    - requires:
      - service: mysql

{{ user }}:
  mysql_user.present:
    - host: {{ salt['pillar.get']('websites:blog.manfred.io:host', 'localhost') }}
    - password: "{{ salt['grains.get_or_set_hash']('%s:password'|format(user)) }}"
    - port: {{ salt['pillar.get']('websites:blog.manfred.io:port', '3306') }}
    - <<: *connections
    - requires:
      - service: mysql

{{ user }}_{{ stuff['database'] }}:
  mysql_grants:
    - present
    - grant: {{ stuff['grants'] }}
    - database: "{{ stuff['database'] }}.*"
    - user: {{ user }}
    - host: {{ salt['pillar.get']('websites:blog.manfred.io:host', 'localhost') }}
    - <<: *connections
    - requires:
      - service: mysql
{% endfor %}
