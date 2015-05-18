websites:
  - blog.manfred.io:
      - users:
          bloguser:
            grants: all
            database: blog
      - host: '192.168.4.%'

replication:
  - host: '192.168.4.%'
  - users:
      replicant:
        grants: "REPLICATION SLAVE"
