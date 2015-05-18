PermitRootLogin:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: "^#?PermitRootLogin yes$"
    - repl: "PermitRootLogin without-password"

  module.run:
    - name: service.restart
    {%- if grains['os_family'] == 'RedHat' %}
    - m_name: sshd
    {%- elif grains['os_family'] == 'Debian' %}
    - m_name: ssh
    {%- endif %}
    - reload: True
    - onchanges:
      - file: /etc/ssh/sshd_config
    - listen:
      - file: /etc/ssh/sshd_config
