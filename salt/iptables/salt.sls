idisable firewalld:
  service.dead:
    - name: firewalld
    - enable: False
  module.run:
    - name: service.mask
    - m_name: firewalld.service
    - onlyif: systemctl is-enabled firewalld.service

iptables rules first:
  iptables.insert:
    - position: 1
    - save: True
    - table: filter
    - chain: INPUT
    - match:
      - state
    - connstate: ESTABLISHED,RELATED
    - jump: ACCEPT

iptables rules loopback:
  iptables.insert:
    - position: 2
    - save: True
    - table: filter
    - chain: INPUT
    - in-interface: lo
    - jump: ACCEPT

iptables rules ssh:
  iptables.append:
    - save: True
    - table: filter
    - chain: INPUT
    - match:
      - state
      - tcp
    - proto: tcp
    - dport: 22
    - connstate: NEW
    - jump: ACCEPT

iptables rules salt:
  iptables.append:
    - save: True
    - table: filter
    - chain: INPUT
    - match:
      - state
      - tcp
    - proto: tcp
    - source: 192.168.4.0/23
    - connstate: NEW
    - jump: ACCEPT

iptables rules last:
  iptables.append:
    - save: True
    - table: filter
    - chain: INPUT
    - jump: REJECT

