<!--img src="assets/rpi.png" align="left" width="144px" height="144px"/-->

<img src="https://raspbernetes.github.io/img/logo.svg" align="left" width="144px"
height="144px"/>

## rpi-k3s / twojastara

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
    -   [version-checker](charts/version-checker) - Checker for newest version of deployed apps
    -   [locust](charts/locust) - template for performance testing
    -   [cert-exporter](charts/cert-exporter) - certificates monitoring
    -   [postgresql](helm/postgresql) - self explanatory
    -   [drone](helm/drone) - CI/CD
    -   [keycloak](helm/keycloak) - identity provider
    -   [nextcloud](helm/nextcloud) - personal cloud service
    -   [calibre-web](helm/calibre-web) - replacement for [ubooquity](yaml/ubooquity)

-   Apps/YAML

    -   [databases](yaml/db) - Mongo, Mysql, CockroachDB
    -   [squid](yaml/squid) - Squid Proxy Service
    -   [ubooquity](yaml/ubooquity) - Books Management
    -   [unifi](yaml/unifi) - Unifi controller/prometheus poller
    -   [www](yaml/www) - Personal website
    -   [prometheus stack](yaml/metrics) - Prometheus/Grafana stack with some additional exporters
    -   [elk stack](yaml/elk) - Elasticsearch/Kibana/Logstash/Filebeat
    -   [registry-ui](yaml/registry-ui) - GUI for managaning docker registry


-   System

    -   [cert-manager](https://github.com/jetstack/cert-manager) - Automated letsencrypt broker
    -   [metallb](yaml/metallb) - Load-balancer for bare-metal with BGP
    -   [longhorn](yaml/storage/longhorn) - longhorn storage


-   Backup

    -   [velero](backup/velero) - Velero backup with minio/s3


-   Varia
    -   [scripts](scripts) - some custom stuff, quite simple
    -   [config](config) - performance and some hardening


<!--START_SECTION_LINES_OF_CODE:readme-info-->
<!--END_SECTION_LINES_OF_CODE:readme-info-->

* * *

## TODO

-   [ ]  Automation
-   [x]  Logging
-   [ ]  Sealed secrets
-   [ ]  Wazuh (security stuff)
-   [x]  Database for apps
-   [ ]  Rewrite helm charts with init containers for database creation

* * *

## :handshake:  Thanks

A lot of inspiration for my cluster came from the people that have shared their
clusters over at [awesome-home-kubernetes].

[awesome-home-kubernetes]: https://github.com/k8s-at-home/awesome-home-kubernetes
