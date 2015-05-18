restart minion:
  module.run:
    - name: service.restart
    - m_name: salt-minion
    - unless: test -f /booted

  file.touch:
    - name: /booted
