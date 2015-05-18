add to loadbalancer:
  runner.loadbalancer.add_all:
    - servers: {{data['items']}}
