# rpi-k3s - Home Cloud on Raspberry Pi
![Kubernetes](https://i.imgur.com/p1RzXjQ.png)

## :computer:&nbsp; Infrastructure
* 2x RPI4 4GB
* 6x RPI4B
* 2x USB DRIVE 1TB

## :gear:&nbsp; Setup

## :wrench:&nbsp; Workloads
* Apps/Helm Charts:
  * [bitwarden](https://bitwarden.com/) - Passwords Management and Storage
  * [gitea](https://github.com/jfelten/gitea-helm-chart) - Git with a cup of tea
  * [gogs](https://gogs.io/) - Gogs: Go Git Service | NOT USED
  * [kanboard](https://kanboard.org/) - Kanban project management software
  * [pihole](https://pi-hole.net/) - Network-wide AD Blocking
  * [registry](https://hub.docker.com/_/registry/) - Docker registry
  * [registry-ui](https://github.com/Joxit/docker-registry-ui) - Docker Registry GUI
* Apps/YAML
  * [databases](yaml/db) - Mongo, Mysql, CockroachDB
  * [elastichq](yaml/elastichq) - Elasticsearch management
  * [nextcloud](yaml/nextcloud) - Very Own Cloud Service
  * [squid](yaml/squid) - Squid Proxy Service
  * [ubooquity](yaml/ubooquity) - Books Management
  * [unifi](yaml/unifi) - Unifi controller
  * [unifi-poller](yaml/unifi-poller) - Unifi pollers for Prometheus
  * [www](yaml/www) - Personal website
  * [metrics](yaml/metrics) - Prometheus/Grafana stack with some additional exporters
* System:
  * [cert-manager](https://github.com/jetstack/cert-manager) - Automated letsencrypt broker
  * [metallb](https://github.com/metallb/metallb) - Load-balancer for bare-metal | NOT USED
  * [kubernetes-dashboard](yaml/kubernetes-dashboard) - Kubernetes Dashboard
  * [storage](yaml/storage) - local-path and nfs
  * [traefik](varia/traefik.yaml) - Traefik
  * [coredns](varia/coredns.yaml) - CoreDNS

### k3s default services
- kube-system
  - svclb - Service LoadBalancer

## TODO
- Automation
- Logging
