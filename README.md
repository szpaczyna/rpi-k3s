## rpi-k3s - Home Cloud on Raspberry Pie(s)

<p align="center">
  <img src="pics/rpi.png" width="140"/>
  <img src="pics/k8s.png" width="140"/>
  <img src="pics/logo.png" width="140"/>
</p>

## Workloads

-   Apps/Helm Charts:
    -   [bitwarden](https://bitwarden.com/) - Passwords Management and Storage
    -   [gitea](https://github.com/jfelten/gitea-helm-chart) - Git with a cup of tea
    -   [kanboard](https://kanboard.org/) - Kanban project management software
    -   [pihole](https://pi-hole.net/) - Network-wide AD Blocking
    -   [registry](https://hub.docker.com/_/registry/) - Docker registry
    -   [version-cehcker](charts/version-checker) - Checker for newest version of deployed apps
    -   [locust](charts/locust) - template for performance testing
    -   [cert-exporter](charts/cert-exporter) - certificates monitoring


-   Apps/YAML
    -   [databases](yaml/db) - Mongo, Mysql, CockroachDB
    -   [squid](yaml/squid) - Squid Proxy Service
    -   [ubooquity](yaml/ubooquity) - Books Management
    -   [unifi](yaml/unifi) - Unifi controller
    -   [unifi poller](yaml/unifi-poller) - Unifi pollers for Prometheus
    -   [www](yaml/www) - Personal website
    -   [prometheus stack](yaml/metrics) - Prometheus/Grafana stack with some additional exporters
    -   [elk stack](yaml/elk) - Elasticsearch/Kibana/Filebeat
    -   [elastichq](yaml/eshq) - Elasticsearch management
    -   [registry-ui](yaml/registry-ui) - GUI for managaning docker registry


-   System
    -   [cert-manager](https://github.com/jetstack/cert-manager) - Automated letsencrypt broker
    -   [metallb](yaml/metallb) - Load-balancer for bare-metal with BGP
    -   [kubernetes-dashboard](yaml/kubernetes-dashboard) - Kubernetes Dashboard
    -   [storage](yaml/storage) - local-path, nfs and samba for home users
    -   [traefik](varia/traefik.yaml) - Traefik
    -   [coredns](varia/coredns.yaml) - CoreDNS

- Backup
    -   [velero](backup/velero) - Velero backup with minio

- Varia
    - [scripts](varia/scripts) - some custom stuff, quite simple
    - [config](varia/config) - performance and some hardening 

```
## TODO
-   Automation
-   Logging (partially done)
-   Wazuh (security stuff)
```
