add to loadbalancer:
  runner.queue.insert:
    - queue: loadbalancer
    - items:
        - {{data['data']['hostname']}}
