dump database:
  salt.state:
    - tgt: dbmaster*
    - sls:
      - mysql.dump

setup replication:
  salt.state:
    - tgt: {{pillar.get('badminion')}}
    - sls:
      - mysql.replication
