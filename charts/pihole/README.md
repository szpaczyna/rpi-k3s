# pihole

## Installation

```
cd <path to repo>
./decrypt.sh
helm install pihole -n <namespace> -f values.yaml .
```

## Values

```
image:
  pullPolicy: IfNotPresent
```
Storage options
```
persistence:
  ## persistence.enabled Enables persistent volume - PV provisioner support necessary
  enabled: true
  ## persistence.keep Keep persistent volume after helm delete
  keep: false
  ## persistence.accessMode PVC Access Mode
  accessMode: ReadWriteMany
  ## persistence.size PVC Size
  size: 5Gi
```
Additional dns entries
```
configData: |-
  server=/local/10.0.0.1
  server=/foobar/10.0.0.2
  address=/.shpaq.org/10.0.0.1
```
Web Interface host for ingrss
```
ingress:
  host: pihole.shpaq.org

```
