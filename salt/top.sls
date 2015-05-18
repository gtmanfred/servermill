base:
  blog*.manfred.io:
    - repos
    - packages
    - websites
    - iptables.web

  db*:
    - mysql
    - iptables.db

  dbmaster.manfred.io:
    - mysql.masterrepl

  salt*:
    - iptables.salt
