{% if 'lag' in data['data'] %}
fix replication:
  runner.state.orch:
    - mods: mysql.fix_replication
    - pillar: 
        badminion: {{data['data']['name']}}
{% endif %}
