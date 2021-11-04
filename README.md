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

    -   [bitwarden](cluster/cluster/helm/bitwarden) - Passwords Management
    -   [gitea](cluster/helm/gitea) - Git with a cup of tea
    -   [kanboard](cluster/helm/kanboard) - Kanban project management software
    -   [pihole](cluster/helm/pihole) - Network-wide AD Blocking
    -   [registry](cluster/helm/registry) - Docker registry
    -   [version-checker](cluster/helm/version-checker) - Checker for newest version of deployed apps
    -   [locust](cluster/helm/locust) - template for performance testing
    -   [cert-exporter](cluster/helm/cert-exporter) - certificates monitoring
    -   [postgresql](cluster/helm/postgresql) - self explanatory
    -   [keycloak](cluster/helm/keycloak) - identity provider
    -   [nextcloud](cluster/helm/nextcloud) - personal cloud service
    -   [calibre-web](cluster/helm/calibre-web) - replacement for [ubooquity](cluster/yaml/ubooquity)
    -   [pgadmin4](cluster/helm/pgadmin) - postgresql managemenet tool
    -   [photoprism](cluster/helm/photoprism) - photos management


-   Apps/YAML

    -   [databases](cluster/apps/db) - Mongo, Mysql, CockroachDB
    -   [unifi](cluster/apps/unifi) - Unifi controller/prometheus poller
    -   [www](cluster/apps/www) - Personal website
    -   [prometheus stack](cluster/apps/monitoring) - Prometheus/Grafana stack with some additional exporters
    -   [elk stack](cluster/apps/logging) - Elasticsearch/Kibana/Logstash/Filebeat
    -   [media downloads](cluster/apps/media) - jackett, bazarr, radarr, lidarr and sonarr

-   System

    -   [cert-manager](https://github.com/jetstack/cert-manager) - Automated letsencrypt broker
    -   [metallb](cluster/core/networking) - Load-balancer for bare-metal with BGP
    -   [longhorn](cluster/helm/longhorn) - longhorn storage

<!--START_SECTION_LINES_OF_CODE:readme-info-->

<!--END_SECTION_LINES_OF_CODE:readme-info-->

* * *

## :handshake:  Thanks

A lot of inspiration for my cluster came from the people that have shared their
clusters over at [awesome-home-kubernetes].

[awesome-home-kubernetes]: https://github.com/k8s-at-home/awesome-home-kubernetes
