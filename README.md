# Deploy Wordpress
My goal with this was to automate everything.

## Prereqs

+ rackspace cloud account
+ make a cloud network

## Deploy

Steps:

1 install salt master
    * pip install pyrax
1 configure master
    1 clone repository
    1 symlink conf to /etc/salt
        1 add cloud information to conf/cloud.providers.d/nova.conf
        1 add network uuid to conf/cloud.profiles.d/nova.conf
            * add network cidr to pillars
        1 configure master: in conf/cloud
        1 configure gitfs in conf/master
            * pillars
            * states
    1 symlink runners to /srv/runners
    1 symlink reactor to /srv/reactor
1 build cloud servers `salt-cloud -Pym map`
1 deploy `salt-run state.orchestrate deploy`

## What does this do

If you check the salt/deploy.sls file, this is what is used to deploy in the
orchestrate above.

First, it checks into the minions, and passes the saltutil.py plugin, to the
minion.  This requires salt:develop, or you need to implement your own
sync_beacons command saltutil.

Next, the db\* servers get setup.  Basic wordpress things get done.  We make
the database and the database user, save all the passwords in grains.  Then
it goes through and adds iptables rules.

NEXT STEP! We start setting up replication.  First we have a state that tells
the master to do a mysqldump, and push it to the master using cp.push.  You
will need to make sure `file_recv: True` is set on the master for this to
work.  Then the next part is `mysql.replication` which tells all the dbslave
servers to grab the dump.sql file from minionfs and add the master pass, user,
and host to the `CHANGE MASTER` line and then import the database.

At this point, it is done configuring the database servers.  The next step is
to setup the web servers.  This does the usual, sets up php-fpm and nginx. It
drops the wordpress files in `/srv/vhosts/{{domain}}/` and adds the hyperdb
and rackspace-cloud-files-cdn plugins, and configures them both.  The last
step is to drop a message in Salt Queue to add the server to a cloud
loadbalancer which will be covered in a minute.

Once the servers are setup, another message is dropped into the queue for
creating the cloud files container for the cdn.  Then salt tells, blog1\* to 
configure wordpress.  It uses the [wp-cli](http://wp-cli.org/) command in 
order to configure the base install.  It does a `wp core install` and
configures the database using the customer wordpress_cli state and wordpress
module.

And the deploy is done.

## What happens next

As I mentioned above, this deployment uses the salt queues.

[Salt Queues](http://docs.saltstack.com/en/latest/ref/runners/all/salt.runners.queue.html)

What this does, it drops a message to be used later, so we avoid race
conditions via api calls.  The loadbalancer.py runner checks that a
loadbalancer is in Active, but if multiple runners hit it at the same time, it
can fail.  So we drop all the servers that need to be added in the queue, and
then work on them all at the same time.  The trigger for working on the stuff
in the queue is in conf/master.d/schedule.conf and will trigger processing
the whole load balancer and cloudfiles containers queues, so that the runners
can be used to automate the creation of all of this.

## Beacons!!!!!

The last thing that gets done is we do one more saltutil.sync_all so that
we make sure the beacons are pulled down (thanks to the first sync_all we
ran at the very beginning).  This step isn't needed if you have the new patch
that got merged.

[patch for sync_beacons](https://github.com/saltstack/salt/pull/23838)

But at the time of writting this, it wasn't merged and I had to pull them down
and restart the minions.

The Beacon is in the pillar/slave.sls file, and it configures the max_lag to
be 100s, and the interval to be 60s.  So every 60 seconds, the 
`mysql.slave_lag` module gets run and if the lag is over 100s, it will
initiate redoing the whole replication, by having a new mysqldump taken from
the master, and importing it into the slave that is lagging.

## Last!

The last thing that needs to be done is to apply the ip address from the
loadbalancer to your DNS.
