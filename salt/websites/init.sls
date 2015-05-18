remove defaults nginx:
  file.absent:
    - names:
      - /etc/nginx/conf.d/default.conf
      - /etc/nginx/conf.d/example_ssl.conf
      - /etc/php-fpm.d/www.conf

/srv/vhosts/:
  file.directory:
    - user: root
    - group: root
    - file_mode: 644
    - dir_mode: 755
    - makedirs: True

{% for domain, stuff in pillar.get('domains', {}).iteritems() %}
{{ domain }}-user:
  user.present:
    - name: {{stuff['user']}}
    - home: /srv/vhosts/{{domain}}

/srv/vhosts/{{domain}}:
  file.directory:
    - user: {{stuff['user']}}
    - group: {{stuff['user']}}
    - file_mode: 664
    - dir_mode: 2775
    - makedirs: True
    - recurse:
      - user
      - group
      - mode

  archive.extracted:
    - source: https://wordpress.org/wordpress-{{stuff['version']}}.tar.gz
    - source_hash: sha1={{stuff['sha1']}}
    - tar_options: v
    - archive_format: tar
    - archive_user: {{stuff['user']}}
    - if_missing: /srv/vhosts/{{domain}}/wordpress

{{ domain }}-nginx:
  file.managed:
    - name: /etc/nginx/conf.d/{{domain}}.conf
    - source: salt://websites/files/domain.conf
    - template: jinja
    - context:
        domain: {{domain}}
    - listen_in:
      - service: nginx

{{ domain }}-php-fpm:
  file.managed:
    - name: /etc/php-fpm.d/{{domain}}.conf
    - source: salt://websites/files/php-fpm.conf
    - template: jinja
    - context:
        domain: {{domain}}
        user: {{stuff['user']}}
    - listen_in:
      - service: php-fpm

{% if salt['grains.has_value']('wp_salt') %}
  {% set wp_salt = grains['wp_salt'] %}
{% else %}
  {% set wp_salt = salt['cmd.run']("/usr/bin/wget -O - -q https://api.wordpress.org/secret-key/1.1/salt/") %}
{% endif %}

{{domain}}-wp-salt:
  grains.present:
    - name: wp_salt
    - value: |
             {{ wp_salt|indent(13, false) }}

{%set dbuser = stuff['mysql']['user']%}
{%set database = stuff['mysql']['database']%}
{%set password  = salt['publish.publish']('dbmaster.manfred.io', 'grains.get', '%s:password'|format(dbuser))['dbmaster.manfred.io']%}
{%set host = salt['publish.publish']('dbmaster.manfred.io', 'grains.get', 'ip4_interfaces:eth2:0')['dbmaster.manfred.io']%}

{{domain}}-wp-config:
  file.managed:
    - name: /srv/vhosts/{{domain}}/wordpress/wp-config.php
    - source: salt://websites/files/wp-config.php
    - template: jinja
    - context:
        user: {{dbuser}}
        database: {{database}}
        password: "{{password}}"
        host: {{host}}

/srv/vhosts/{{domain}}/wordpress/wp-content/db.php:
  file.managed:
    - source: salt://websites/files/db.php
    - user: {{stuff['user']}}
    - group: {{stuff['user']}}

/srv/vhosts/{{domain}}/wordpress/db-config.php:
  file.managed:
    - source: salt://websites/files/db-config.php
    - user: {{stuff['user']}}
    - group: {{stuff['user']}}
    - template: jinja
    - context:
        dbmaster: {{salt['publish.publish']('dbmaster*', 'grains.items') or {}}}
        dbslave: {{salt['publish.publish']('dbslave*', 'grains.items') or {}}}
        user: {{dbuser}}
        database: {{database}}

{% set cloud = salt['pillar.get']('cloud', {}) %}
/srv/vhosts/{{domain}}/wordpress/wp-content/plugins:
  archive.extracted:
    - source: salt://websites/files/rackspace-cloud-files-cdn.zip
    - archive_format: zip
    - archive_user: {{stuff['user']}}
    - if_missing: /srv/vhosts/{{domain}}/wordpress/wp-content/plugins/rackspace-cloud-files-cdn

  file.managed:
    - name: /srv/vhosts/{{domain}}/wordpress/wp-content/plugins/rackspace-cloud-files-cdn/rackspace-cdn.php
    - source: salt://websites/files/rackspace-cdn.php
    - template: jinja
    - context:
        region: {{cloud['region']}}
        username: {{cloud['username']}}
        api_key: {{cloud['api_key']}}
        domain: {{domain}}

{% endfor %}

php-fpm service:
  service.running:
    - name: php-fpm
    - enable: True

nginx service:
  service.running:
    - name: nginx
    - enable: True

add to loadbalancer:
  event.send:
    - order: last
    - name: salt/{{salt['grains.get']('fqdn')}}/loadbalancer
    - data:
        hostname: {{salt['grains.get']('fqdn')}}
