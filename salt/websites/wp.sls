/usr/local/bin/wp:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    - source_hash: sha1=944f67aa71eb6b07694ce1a93ac3115b82a329cc
    - reload_modules: True

{% for domain, stuff in pillar.get('domains', {}).iteritems() %}
check cloudfiles container:
  event.send:
    - name: salt/{{domain}}/cloudfilescdn
    - data:
        name: {{domain}}

do install:
  wordpress_cli.installed:
    - path: /srv/vhosts/{{domain}}/wordpress/
    - user: {{stuff['user']}}
    - admin_user: {{stuff['wordpress']['user']}}
    - admin_password: "{{ salt['grains.get_or_set_hash']('%s-%s:password'|format(domain, stuff['wordpress']['user'])) }}"
    - admin_email: {{stuff['wordpress']['email']}}
    - title: {{stuff['wordpress']['title']}}
    - url: {{stuff['wordpress']['url']}}

activate plugin:
  wordpress_cli.activated:
    - name: rackspace-cloud-files-cdn
    - path: /srv/vhosts/{{domain}}/wordpress/
    - user: {{stuff['user']}}
{% endfor %}
