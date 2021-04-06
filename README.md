<img src="assets/rpi.png" align="left" width="130"/>      
<img src="https://raspbernetes.github.io/img/logo.svg" align="left" width="130px" height="130px"/>

## rpi-k3s
### Home Cloud on Raspberry Pie(s)
<br>
<!--START_SECTION_PROFILE_VIEWS:readme-info-->

<!--END_SECTION_PROFILE_VIEWS:readme-info-->

* * *

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
    -   [elk stack](yaml/elk) - Elasticsearch/Kibana/Logstash/Filebeat
    -   [elastichq](yaml/eshq) - Elasticsearch management
    -   [registry-ui](yaml/registry-ui) - GUI for managaning docker registry


-   System

    -   [cert-manager](https://github.com/jetstack/cert-manager) - Automated letsencrypt broker
    -   [metallb](yaml/metallb) - Load-balancer for bare-metal with BGP
    -   [kubernetes-dashboard](yaml/kubernetes-dashboard) - Kubernetes Dashboard
    -   [storage](yaml/storage) - local-path, nfs and samba for home users
    -   [traefik](varia/traefik.yaml) - Traefik
    -   [coredns](varia/coredns.yaml) - CoreDNS


-   Backup

    -   [velero](backup/velero) - Velero backup with minio


-   Varia
    -   [scripts](varia/scripts) - some custom stuff, quite simple
    -   [config](varia/config) - performance and some hardening

* * *

## Docker Stuff

> <https://github.com/szpaczyna/docker>

#### Images

-   [gitlab-ce](https://hub.docker.com/repository/docker/szpaczyn/gitlab-ce)
-   [elastic-hq](https://hub.docker.com/repository/docker/szpaczyn/elastic-hq)
-   [cockroachdb](https://hub.docker.com/repository/docker/szpaczyn/cockroachdb)
-   [squid](https://hub.docker.com/repository/docker/szpaczyn/squid)
-   [elasticsearch](https://hub.docker.com/repository/docker/szpaczyn/elasticsearch-arm64)
-   [kibana](https://hub.docker.com/repository/docker/szpaczyn/kibana-arm64)
-   [logstash](https://hub.docker.com/repository/docker/szpaczyn/logstash-arm64)
-   [elastic-curator](https://hub.docker.com/repository/docker/szpaczyn/elasticsearch-curator)
-   [xbrowsersync](https://hub.docker.com/repository/docker/szpaczyn/xbrowsersync)

## Helm

> <https://szpaczyna.github.io/rpi-k3s>

    helm repo add shpaq https://szpaczyna.github.io/rpi-k3s
    helm repo update

<!--START_SECTION_LINES_OF_CODE:readme-info-->

<!--END_SECTION_LINES_OF_CODE:readme-info-->

* * *

## TODO

-   Automation
-   Logging (partially done)
-   Wazuh (security stuff)
-   Zalando postgres operator

* * *

## :handshake:  Thanks

A lot of inspiration for my cluster came from the people that have shared their
clusters over at [awesome-home-kubernetes].

[awesome-home-kubernetes]: https://github.com/k8s-at-home/awesome-home-kubernetes
