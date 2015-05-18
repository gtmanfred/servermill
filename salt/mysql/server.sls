{% set mysql_root_password = salt['grains.get_or_set_hash']('mysql:server:root_password') %}

mysql_debconf_utils:
  pkg.installed:
    - name: debconf-utils

mysql_debconf:
  debconf.set:
    - name: mysql-server
    - data:
        'mysql-server/root_password': {'type': 'password', 'value': '{{ mysql_root_password }}'}
        'mysql-server/root_password_again': {'type': 'password', 'value': '{{ mysql_root_password }}'}
        'mysql-server/start_on_boot': {'type': 'boolean', 'value': 'true'}
    - require_in:
      - pkg: mysqld
    - require:
      - pkg: mysql_debconf_utils

mysqld:
  pkg.installed:
    - name: mysql-server
    - require:
      - debconf: mysql_debconf

  file.managed:
    - name: /etc/mysql/conf.d/bind.cnf
    - contents: |
        [mysqld]
        bind-address = {{ salt['grains.get']('ip4_interfaces:eth2', '')[0] }}
    - require:
      - pkg: mysql-server

  service.running:
    - name: mysql
    - listen:
      - file: mysqld

{% set serverid = salt['grains.get']('ip4_interfaces:eth2:0').split('.')[-1] %}
/etc/mysql/conf.d/binarylogs.cnf:
  file.managed:
    - contents: |
        [mysqld]
        server-id={{serverid}}
        {%- if pillar.get('master') %}
        log_bin=/var/log/mysql/bin-{{serverid}}.log
        {%- endif %}
    - listen_in:
      - service: mysql

/root/.my.cnf:
  file.managed:
    - contents: |
        [client]
        user=root
        password="{{mysql_root_password}}"
