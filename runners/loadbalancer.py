#!py

import requests
import json
import os.path
import salt.config as sac
import salt.cloud
import salt.client

import logging
import pprint
import time
log = logging.getLogger(__name__)


def _wait_for_loadbalancer(loadbalancer, lbendpoint, headers):
    def _get_loadbalancer():
        return requests.get(
            '{0}/loadbalancers/{1}'.format(
                lbendpoint,
                loadbalancer
            ),
            headers=headers
        ).json().get('loadBalancer', {})

    count = 0
    while _get_loadbalancer()['status'] != 'ACTIVE' and count < 10:
        time.sleep(5)
        count += 1

    return True

def add(server):
    config = sac.cloud_config('/etc/salt/cloud')
    master = sac.master_config('/etc/salt/master')
    api_key = config['providers']['my-nova']['nova']['api_key']
    ident = config['providers']['my-nova']['nova']['identity_url']
    tenant = config['providers']['my-nova']['nova']['tenant']
    user = config['providers']['my-nova']['nova']['user']
    region = config['providers']['my-nova']['nova']['compute_region']
    loadbalancer = master['loadbalancer']['name']
    lbendpoint = 'https://{0}.loadbalancers.api.rackspacecloud.com/v1.0/{1}'.format(region, tenant)
    sendpoint = 'https://{0}.servers.api.rackspacecloud.com/v2/{1}'.format(region, tenant)
    headers = {
      'Content-Type': 'application/json'
    }
    payload={
      "auth": {
        "RAX-KSKEY:apiKeyCredentials": {
          "username": user,
          "apiKey": api_key
        }
      }
    }
    ret = requests.post(os.path.join(ident, 'tokens'), data=json.dumps(payload), headers=headers).json()
    headers['X-Auth-Token'] = ret['access']['token']['id']

    loadbalancers = requests.get('{0}/loadbalancers'.format(lbendpoint), headers=headers).json().get('loadBalancers', {})
    lb = None
    for l in loadbalancers:
        if l['name'] == loadbalancer:
            lb = l
            break

    if lb is None:
        lb = create()
        if ret is False:
            log.debug("Failed to create loadbalancer: {0}".format(loadbalancer))
            return ret

    servers = requests.get('{0}/servers/detail?name={1}'.format(sendpoint, server), headers=headers).json().get('servers', [])
    if servers and servers[0]['name'] == server:
        serverjson = servers[0]
        private_ip = serverjson['addresses']['private'][0]['addr']
    else:
        log.debug("Server doesn't exist: {0}".format(server))
        return False

    nodes = requests.get('{0}/loadbalancers/{1}/nodes'.format(lbendpoint, lb['id']), headers=headers).json().get('nodes', [])
    for node in nodes:
        if node['address'] == private_ip:
            log.debug('Server already exists in loadbalancer: {0}'.format(server))
            return None

    payload = json.dumps({
        "nodes": [
             {
                 "address": private_ip,
                 "port": 80,
                 "condition": "ENABLED",
                 "type":"PRIMARY"
             }
        ]
    })
    if _wait_for_loadbalancer(lb['id'], lbendpoint, headers):
        ret = requests.post('{0}/loadbalancers/{1}/nodes'.format(lbendpoint, lb['id']), headers=headers, data=payload).json()
        return ret
    else:
        log.debug('Loadbalancer stuck not in Active: {0}'.format(loadbalancer))
        return False


def add_all(servers):
    ret = []
    for server in servers:
        ret.append(add(server))
    return ret


def remove(server):
    config = sac.cloud_config('/etc/salt/cloud')
    master = sac.master_config('/etc/salt/master')
    api_key = config['providers']['my-nova']['nova']['api_key']
    ident = config['providers']['my-nova']['nova']['identity_url']
    tenant = config['providers']['my-nova']['nova']['tenant']
    user = config['providers']['my-nova']['nova']['user']
    region = config['providers']['my-nova']['nova']['compute_region']
    loadbalancer = master['loadbalancer']['name']
    lbendpoint = 'https://{0}.loadbalancers.api.rackspacecloud.com/v1.0/{1}'.format(region, tenant)
    sendpoint = 'https://{0}.servers.api.rackspacecloud.com/v2/{1}'.format(region, tenant)
    headers = {
      'Content-Type': 'application/json'
    }
    payload={
      "auth": {
        "RAX-KSKEY:apiKeyCredentials": {
          "username": user,
          "apiKey": api_key
        }
      }
    }
    ret = requests.post(os.path.join(ident, 'tokens'), data=json.dumps(payload), headers=headers).json()
    headers['X-Auth-Token'] = ret['access']['token']['id']

    loadbalancers = requests.get('{0}/loadbalancers'.format(lbendpoint), headers=headers).json().get('loadBalancers', {})
    lb = None
    for l in loadbalancers:
        if l['name'] == loadbalancer:
            lb = l
            break

    if lb is None:
        log.debug("Loadbalancer doesn't exist: {0}".format(loadbalancer))
        return False

    servers = requests.get('{0}/servers/detail?name={1}'.format(sendpoint, server), headers=headers).json().get('servers', [])
    if servers and servers[0]['name'] == server:
        serverjson = servers[0]
        private_ip = serverjson['addresses']['private'][0]['addr']
    else:
        log.debug("Server doesn't exist: {0}".format(server))
        return False

    nodes = requests.get('{0}/loadbalancers/{1}/nodes'.format(lbendpoint, lb['id']), headers=headers).json().get('nodes', {})
    n = None
    for node in nodes:
        if node['address'] == private_ip:
            n = node
            break

    if n is None:
        log.debug("Server doesn't exists in loadbalancer: {0}".format(server))
        return None

    payload = json.dumps({
        "nodes": [
             {
                 "address": private_ip,
                 "port": 80,
                 "condition": "ENABLED",
                 "type":"PRIMARY"
             }
        ]
    })
    if _wait_for_loadbalancer(lb['id'], lbendpoint, headers):
        ret = requests.delete('{0}/loadbalancers/{1}/nodes/{2}'.format(lbendpoint, lb['id'], n['id']), headers=headers)
        if ret.status_code == 202:
            return True
        else:
            log.debug('Failed to remove node: {0}'.format(server))
            return False
    else:
        log.debug('Loadbalancer stuck not in Active: {0}'.format(loadbalancer))
        return False


def remove_multiple(servers):
    ret = []
    for server in servers:
        ret.append(remove(server))
        time.sleep(5)
    return ret


def create():
    config = sac.cloud_config('/etc/salt/cloud')
    master = sac.master_config('/etc/salt/master')
    api_key = config['providers']['my-nova']['nova']['api_key']
    ident = config['providers']['my-nova']['nova']['identity_url']
    tenant = config['providers']['my-nova']['nova']['tenant']
    user = config['providers']['my-nova']['nova']['user']
    region = config['providers']['my-nova']['nova']['compute_region']
    loadbalancer = master['loadbalancer']['name']
    port = master['loadbalancer']['port']
    lbendpoint = 'https://{0}.loadbalancers.api.rackspacecloud.com/v1.0/{1}'.format(region, tenant)
    headers = {
      'Content-Type': 'application/json'
    }
    payload={
      "auth": {
        "RAX-KSKEY:apiKeyCredentials": {
          "username": user,
          "apiKey": api_key
        }
      }
    }
    ret = requests.post(os.path.join(ident, 'tokens'), data=json.dumps(payload), headers=headers).json()
    headers['X-Auth-Token'] = ret['access']['token']['id']

    loadbalancers = requests.get('{0}/loadbalancers'.format(lbendpoint), headers=headers).json().get('loadBalancers', {})
    for l in loadbalancers:
        if l['name'] == loadbalancer:
            log.debug('Loadbalancer exists: {0}'.format(loadbalancer))
            return None

    payload = json.dumps({
        "loadBalancer": {
            "name": loadbalancer,
            "port": port,
            "protocol": "HTTP",
            "virtualIps": [
                {"type": "PUBLIC"}
            ]
        }
    })
    ret = requests.post('{0}/loadbalancers'.format(lbendpoint), headers=headers, data=payload).json().get('loadBalancer', {})
    _wait_for_loadbalancer(ret['id'], lbendpoint, headers)
    return ret


def delete():
    config = sac.cloud_config('/etc/salt/cloud')
    master = sac.master_config('/etc/salt/master')
    api_key = config['providers']['my-nova']['nova']['api_key']
    ident = config['providers']['my-nova']['nova']['identity_url']
    tenant = config['providers']['my-nova']['nova']['tenant']
    user = config['providers']['my-nova']['nova']['user']
    region = config['providers']['my-nova']['nova']['compute_region']
    loadbalancer = master['loadbalancer']['name']
    port = master['loadbalancer']['port']
    lbendpoint = 'https://{0}.loadbalancers.api.rackspacecloud.com/v1.0/{1}'.format(region, tenant)
    headers = {
      'Content-Type': 'application/json'
    }
    payload={
      "auth": {
        "RAX-KSKEY:apiKeyCredentials": {
          "username": user,
          "apiKey": api_key
        }
      }
    }
    ret = requests.post(os.path.join(ident, 'tokens'), data=json.dumps(payload), headers=headers).json()
    headers['X-Auth-Token'] = ret['access']['token']['id']

    loadbalancers = requests.get('{0}/loadbalancers'.format(lbendpoint), headers=headers).json().get('loadBalancers', {})
    lb = None
    for l in loadbalancers:
        if l['name'] == loadbalancer:
            lb = l

    if lb is None:
        log.debug("Loadbalancer doesn't exist: {0}".format(loadbalancer))
        return False

    if _wait_for_loadbalancer(lb['id'], lbendpoint, headers):
        ret = requests.delete('{0}/loadbalancers/{1}'.format(lbendpoint, lb['id']), headers=headers)
    else:
        log.debug("Loadbalancer stuck not in Active: {0}".format(loadbalancer))
        return False

    if ret.status_code == 202:
        return True
    else:
        return False
