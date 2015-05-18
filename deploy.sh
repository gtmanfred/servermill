#!/bin/bash
mkdir /etc/salt

curl -sL https://bootstrap.saltstack.com | sh -s -- -MP git develop
pip install pyrax GitPython

for dir in $PWD/cloud* $PWD/master* $PWD/minion*; do
  ln -sf $dir /etc/salt/
done

for dir in $PWD/runners $PWD/reactor; do
  ln -sf $dir /srv
done

systemctl restart salt-master salt-minion
salt-cloud -Pym map
salt-run state.orch deploy
