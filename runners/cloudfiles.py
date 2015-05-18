#!py

from __future__ import print_function

import requests
import json
import os.path
import salt.config as sac
import salt.cloud
import salt.client
from salt.utils.cloud import fire_event

import logging
import pprint
import time
log = logging.getLogger(__name__)


def _get_endpoint(etype, region, catalog):
    endpoints = None
    for e in catalog:
        if e['type'] == etype:
            endpoints = e['endpoints']
            break

    if endpoints is None:
        log.debug('No endpoint found for object-store: {0}'.format(container))
        return False

    endpoint = None
    for e in endpoints:
        if e['region'] == region: 
            if 'internalURL' in e:
                endpoint = e['internalURL']
            else:
                endpoint = e['publicURL']
            break

    if endpoint is not None:
        return endpoint
    else:
        log.debug('No endpoint found in {0}: {1}'.format(region, container))
        return False


def create(container):
    config = sac.cloud_config('/etc/salt/cloud')
    master = sac.master_config('/etc/salt/master')
    api_key = config['providers']['my-nova']['nova']['api_key']
    ident = config['providers']['my-nova']['nova']['identity_url']
    tenant = config['providers']['my-nova']['nova']['tenant']
    user = config['providers']['my-nova']['nova']['user']
    region = config['providers']['my-nova']['nova']['compute_region']
    headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }
    payload={
      "auth": {
        "RAX-KSKEY:apiKeyCredentials": {
          "username": user,
          "apiKey": api_key
        }
      }
    }
    identity = requests.post(os.path.join(ident, 'tokens'), data=json.dumps(payload), headers=headers).json().get('access', {})
    headers['X-Auth-Token'] = identity['token']['id']
    catalog = identity['serviceCatalog']

    endpoint = _get_endpoint('object-store', region, catalog)

    containers = requests.get(endpoint, headers=headers).json()
    for c in containers:
        if c['name'] == container:
            log.debug('Container already exists!: {1}'.format(region, container))
            fire_event('enablecontainer', {'name': container}, 'salt/{0}/enablecontainer'.format(container))
            return None

    ret = requests.put('{0}/{1}'.format(endpoint, container), headers=headers)
    if ret.status_code == 201:
        fire_event('enablecontainer', {'name': container}, 'salt/{0}/enablecontainer'.format(container))
        return True
    else:
        log.debug('Failed to create container: {0}'.format(container))
        return False


def create_all(containers):
    ret = []
    for container in containers:
        ret.append(create(container))
    return ret


def enable(container):
    with open('/tmpwat', 'w') as what:
        print('what', file=what)
    config = sac.cloud_config('/etc/salt/cloud')
    master = sac.master_config('/etc/salt/master')
    api_key = config['providers']['my-nova']['nova']['api_key']
    ident = config['providers']['my-nova']['nova']['identity_url']
    tenant = config['providers']['my-nova']['nova']['tenant']
    user = config['providers']['my-nova']['nova']['user']
    region = config['providers']['my-nova']['nova']['compute_region']
    headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }
    payload={
      "auth": {
        "RAX-KSKEY:apiKeyCredentials": {
          "username": user,
          "apiKey": api_key
        }
      }
    }
    identity = requests.post(os.path.join(ident, 'tokens'), data=json.dumps(payload), headers=headers).json().get('access', {})
    headers['X-Auth-Token'] = identity['token']['id']
    catalog = identity['serviceCatalog']

    endpoint = _get_endpoint('object-store', region, catalog)
    cdnendpoint = _get_endpoint('rax:object-cdn', region, catalog)

    containers = requests.get(endpoint, headers=headers).json()
    cont = None
    for c in containers:
        if c['name'] == container:
            cont = c
            log.debug('Container: \n{0}'.format(pprint.pformat(cont)))
            log.debug('Container: \n{0}'.format(pprint.pformat(headers)))
            log.debug('Container: \n{0}'.format(pprint.pformat(endpoint)))
            break

    if cont is None:
        log.debug("Container doesn't exist: {0}".format(container))
        return False

    headers['X-Ttl'] = 900
    headers['X-Cdn-Enabled'] = 'True'
    ret = requests.put('{0}/{1}'.format(cdnendpoint, container), headers=headers)
    if ret.status_code == 201:
        return True
    elif ret.status_code == 202:
        log.debug('Container already enabled: {0}'.format(container))
        return None
    else:
        log.debug('Failed to enable container: {0}'.format(container))
        return False


def enable_all(containers):
    ret = []
    for container in containers:
        ret.append(enable(container))
    return ret
