#!/usr/bin/python

"""
Looks at your current kubernetes cluster and creates the following structure:
{
  "cluster" : {
    "allocatable": { "cpu": <millicores>, "memory": <bytes> },
    "limits": { "cpu": <millicores>, "memory": <bytes> },
    "requests": { "cpu": <millicores>, "memory": <bytes> },
    "usage": { "cpu": <millicores>, "memory": <bytes> },
  },
  "<nodeid>" : {
    "allocatable": { "cpu": <millicores>, "memory": <bytes> },
    "limits": { "cpu": <millicores>, "memory": <bytes> },
    "requests": { "cpu": <millicores>, "memory": <bytes> },
    "usage": { "cpu": <millicores>, "memory": <bytes> },
    "pods": {
      "<namespace>/<pod>" : {
        "limits": { "cpu": <millicores>, "memory": <bytes> },
        "requests": { "cpu": <millicores>, "memory": <bytes> },
        "usage": { "cpu": <millicores>, "memory": <bytes> },
        "containers" : {
          "<containername>" : {
            "limits": { "cpu": <millicores>, "memory": <bytes> },
            "requests": { "cpu": <millicores>, "memory": <bytes> },
            "usage": { "cpu": <millicores>, "memory": <bytes> },
          },
          ...
        },
        ...
      },
    },
  },
  ...
}
"""

import json
import os,subprocess,shlex

def convert_cpu(string,human=False):
  if string.endswith("m"):
    v = int(string[0:-1])
  else:
    v = int(string)*1000
  if not human:
    return v
  if v % 1000 == 0:
    return str(int(v/(1000)))

def convert_memory(string,human=False):
  if string.endswith("K") or string.endswith("k"):
    v = int(string[0:-1])*1000
  elif string.endswith("M") or string.endswith("m"):
    v = int(string[0:-1])*1000*1000
  elif string.endswith("G") or string.endswith("g"):
    v = int(string[0:-1])*1000*1000*1000
  elif string.endswith("Ki"):
    v = int(string[0:-2])*1024
  elif string.endswith("Mi"):
    v = int(string[0:-2])*1024*1024
  elif string.endswith("Gi"):
    v = int(string[0:-2])*1024*1024*1024
  else:
    v = int(string)
  if not human:
    return v
  if v > 1024*1024:
    return str(int(v/(1024*1024))) + "G"
  if v > 1024:
    return str(int(v/(1024))) + "M"

def deep_sum(add,dest):
  for k in add.keys():
    if k == "containers":
      continue
    if type(add[k]) is dict:
      if k not in dest:
        dest[k] = {}
      deep_sum(add[k],dest[k])
    else:
      if k not in dest:
        dest[k] = 0
      dest[k] += add[k]

def get_usage():
  cmd = "kubectl get pods --all-namespaces -o json"
  pods = json.loads(subprocess.check_output(shlex.split(cmd)))
  cmd = "kubectl get nodes --all-namespaces -o json"
  nodes = json.loads(subprocess.check_output(shlex.split(cmd)))
  cmd = "kubectl top pods --all-namespaces --containers=true"
  pod_util = subprocess.check_output(shlex.split(cmd))
  cmd = "kubectl top nodes"
  node_util = subprocess.check_output(shlex.split(cmd))

  pod_node = {}

  out = {}
  for node in nodes['items']:
    nname = node['metadata']['name']
    out[nname] = {
      "pods":{},
      "allocatable" : {
        "cpu": convert_cpu(node['status']['allocatable']['cpu']),
        "memory": convert_memory(node['status']['allocatable']['memory']),
      }
    }
  for pod in pods['items']:
    pname = pod['metadata']['namespace'] + "/" + pod['metadata']['name']
    if 'nodeName' not in pod['spec']:
      # probably a pending pod
      continue
    node = pod['spec']['nodeName']
    pod_node[pname] = node
    out[node]['pods'][pname] = {"containers":{}}
    pod_total = out[node]['pods'][pname]
    for c in pod['spec']['containers']:
      cname = c['name']
      out[node]['pods'][pname]['containers'][cname] = {}

      usage = {
        "requests": { "cpu": 0, "memory": 0 },
        "limits": { "cpu": 0, "memory": 0 }
      }
      r = c['resources']
      # yes this is ugly
      if 'requests' in r and 'cpu' in r['requests']:
        usage['requests']['cpu'] = convert_cpu(r['requests']['cpu'])
      if 'limits' in r and 'cpu' in r['limits']:
        usage['limits']['cpu'] = convert_cpu(r['limits']['cpu'])
      if 'requests' in r and 'memory' in r['requests']:
        usage['requests']['memory'] = convert_memory(r['requests']['memory'])
      if 'limits' in r and 'memory' in r['limits']:
        usage['limits']['memory'] = convert_memory(r['limits']['memory'])
      deep_sum(usage,pod_total)

      out[node]['pods'][pname]['containers'][cname] = usage
    deep_sum(pod_total,out[node])

  # put in current usage
  for line in pod_util.splitlines():
    (namespace,pod,container,cpu,memory) = line.split()
    if namespace == "NAMESPACE":
      continue
    pname = namespace + "/" + pod
    usage = {'cpu': convert_cpu(cpu), 'memory': convert_memory(memory)}
    try:
      out[pod_node[pname]]['pods'][pname]['containers'][container]['usage'] = usage
    except:
      pass

  # add up total cluster usage
  cluster_usage = {}
  for node in out.keys():
    out[node]['usage'] = {}
    for pod in out[node]['pods'].keys():
      out[node]['pods'][pod]['usage'] = { "cpu": 0, "memory": 0 }
      for container in out[node]['pods'][pod]['containers'].keys():
        if 'usage' in out[node]['pods'][pod]['containers'][container]:
          deep_sum(out[node]['pods'][pod]['containers'][container]['usage'],out[node]['pods'][pod]['usage'])
      deep_sum(out[node]['pods'][pod]['usage'],out[node]['usage'])
    deep_sum(out[node]['usage'],cluster_usage)

  out['cluster'] = {'usage':cluster_usage,'requests':{},'limits':{}, 'allocatable': {}}
  for node in nodes['items']:
    nname = node['metadata']['name']
    deep_sum(out[nname]['requests'],out['cluster']['requests'])
    deep_sum(out[nname]['limits'],out['cluster']['limits'])
    deep_sum(out[nname]['allocatable'],out['cluster']['allocatable'])

  return out

if __name__ == '__main__':
  result = get_usage()
  print(json.dumps(result,indent=4,sort_keys=True))
