ius:
  pkgrepo.managed:
    - humanname: IUS Community Packages for Enterprise Linux 7 - $basearch
    - gpgcheck: 1
    - gpgkey: http://dl.iuscommunity.org/pub/ius/IUS-COMMUNITY-GPG-KEY
    - enabled: 1
    - failovermethod: priority
    - names:
      - ius:
        - mirrorlist: "http://dmirr.iuscommunity.org/mirrorlist/?repo=ius-centos7&arch=$basearch"
      - ius-testing:
        - mirrorlist: "http://dmirr.iuscommunity.org/mirrorlist/?repo=ius-centos7-testing&arch=$basearch"

nginx-official-repo:
  pkgrepo.managed:
    - name: nginx
    - humanname: nginx repo
    - baseurl: http://nginx.org/packages/centos/$releasever/$basearch/
    - gpgcheck: 0
    - enabled: 1
