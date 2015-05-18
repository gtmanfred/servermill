db_setup:
  salt.state:
    - tgt: 'db*'
    - sls:
      - modules
      - mysql.python

dbmaster_setup:
  salt.state:
    - tgt: 'db*'
    - highstate: True

dump database:
  salt.state:
    - tgt: dbmaster*
    - sls:
      - mysql.dump

setup replication:
  salt.state:
    - tgt: dbslave*
    - sls:
      - mysql.replication

web_setup:
  salt.state:
    - tgt: 'blog*'
    - highstate: True

install wordpress:
  salt.state:
    - tgt: 'blog1*'
    - sls:
      - websites.wp

restart minions:
  salt.state:
    - tgt: '*'
    - sls:
      - modules
      - minion
