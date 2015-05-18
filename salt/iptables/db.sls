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

iptables rules mysql:
  iptables.append:
    - save: True
    - table: filter
    - chain: INPUT
    - match:
      - state
      - tcp
    - proto: tcp
    - dport: 3306
    - source: "{{ salt['pillar.get']('private:network', '0.0.0.0/0') }}"
    - connstate: NEW
    - jump: ACCEPT

iptables rules last:
  iptables.append:
    - save: True
    - table: filter
    - chain: INPUT
    - jump: REJECT

