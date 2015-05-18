create container:
  runner.queue.insert:
    - queue: cloudfiles
    - items:
        - {{data['data']['name']}}
