{% if salt['mysql.slave_lag']() >= 100 or salt['mysql.slave_lag']() < 0 %}
{% set mysql_root_password = salt['grains.get_or_set_hash']('mysql:server:root_password') %}
{% set user = salt['pillar.get']('replication:users', {}).keys()[0] %}
{% set host = salt['publish.publish']('dbmaster.manfred.io', 'grains.get', 'ip4_interfaces:eth2:0')['dbmaster.manfred.io'] %}
{% set password = salt['publish.publish']('dbmaster.manfred.io', 'grains.get', '%s:password'|format(user))['dbmaster.manfred.io'] %}
stop slave:
  cmd.run:
    - name: "mysqladmin -u root -p'{{mysql_root_password}}' stop-slave"

get dump:
  file.managed:
    - name: /dump.sql
    - source: salt://dbmaster.manfred.io/dump.sql

setup dump:
  file.replace:
    - name: /dump.sql
    - pattern: "(CHANGE MASTER TO [^;]+);"
    - repl: "\\1, MASTER_USER='{{user}}', MASTER_HOST='{{host}}', MASTER_PASSWORD='{{password}}';"

import dump:
  cmd.run:
    - name: "mysql -u root -p'{{mysql_root_password}}' < /dump.sql"

start slave:
  cmd.run:
    - name: "mysqladmin -u root -p'{{mysql_root_password}}' start-slave"

{% endif %}

delete dump:
  file.absent:
    - name: /dump.sql

