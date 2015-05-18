# -*- coding: utf-8 -*-
'''
Beacon to emit system load averages
'''

# Import Python libs
from __future__ import absolute_import
import logging
import os

# Import Salt libs
import salt.utils

log = logging.getLogger(__name__)

__virtualname__ = 'slave_lag'


def __virtual__():
    if salt.utils.is_windows():
        return False
    else:
        return __virtualname__


def beacon(config):
    '''
    Check that the slaves are nog lagging behind

    .. code-block:: yaml

        beacons:
          - slave_lag:
              max: 100

    '''
    log.trace('slave_lag beacon starting')
    lag = __salt__['mysql.slave_lag']()
    if lag > config['max_lag'] or lag < 0:
        return [{'lag': lag, 'name': __salt__['grains.get']('fqdn')}]
    return [{}]
