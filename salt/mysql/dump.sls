{% set dbs = [] %}
{% for user, stuff in salt['pillar.get']('websites:blog.manfred.io:users').iteritems() %}
{% do dbs.append(stuff['database']) %}
{% endfor %}
database dumps for slave:
  cmd.run:
    - name: mysqldump -u root -h localhost -p'{{ salt['config.get']('mysql:server:root_password', '') }}' --master-data=1 --databases {{dbs|join(' ')}} > /dump.sql

  module.run:
    - name: cp.push
    - path: /dump.sql
