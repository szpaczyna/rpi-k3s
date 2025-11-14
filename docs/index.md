---
layout: default
---

## Workloads

- Apps/Helm Charts:
    - [bitwarden](cluster/helm/bitwarden) - Passwords Management
    - [gitea](cluster/helm/gitea) - Git with a cup of tea
    - [kanboard](cluster/helm/kanboard) - Kanban project management software
    - [nextcloud](cluster/helm/nextcloud) - Personal cloud service
    - [postgresql](cluster/helm/postgresql) - PostgreSQL database
    - [version-checker](cluster/helm/version-checker) - Checker for newest version of deployed apps
    - [influxdb](cluster/helm/influxdb) - Database for Apple Health exports
    - [shpaq-org](cluster/helm/shpaq-org) - Personal website
    - [media-stack](cluster/helm/media-stack) - Transmission, Radarr, Lidarr, Sonarr, Bazarr, Jackett, Calibre-web
    - [grafana](cluster/helm/grafana) - Grafana (for dashboards)

- Apps/YAML:
    - [unifi](cluster/apps/unifi) - Unifi controller/prometheus poller
    - [gentoo](cluster/apps/gentoo) - cross-compiler and playground

- System:
    - [prometheus](cluster/helm/prometheus) - Prometheus monitoring system
    - [cert-manager](cluster/helm/cert-manager) - Automated letsencrypt broker
    - [metallb](cluster/core/networking) - Load-balancer for bare-metal with BGP
    - [longhorn](cluster/helm/longhorn) - Distributed storage system
    - [ingress-nginx](cluster/helm/ingress-nginx) - Ingress controller
    - [x509-certificate-exporter](cluster/helm/x509-certificate-exporter) - Certificates monitoring
    - [openweather-exporter](cluster/helm/openweather) - OpenWeather API exporter
    - [loki](cluster/helm/loki) - Log aggregation system
    - [event-exporter](cluster/helm/event-exporter) - Kubernetes events exporter
    - [local-path-provisioner](cluster/helm/local-path-provisioner) - Local storage provisioner


## Docker Stuff

> <https://github.com/szpaczyna/docker>

### Images

- [gitlab-ce](https://hub.docker.com/repository/docker/szpaczyn/gitlab-ce)
- [elastic-hq](https://hub.docker.com/repository/docker/szpaczyn/elastic-hq)
- [cockroachdb](https://hub.docker.com/repository/docker/szpaczyn/cockroachdb)
- [squid](https://hub.docker.com/repository/docker/szpaczyn/squid)
- [elasticsearch](https://hub.docker.com/repository/docker/szpaczyn/elasticsearch-arm64)
- [kibana](https://hub.docker.com/repository/docker/szpaczyn/kibana-arm64)
- [logstash](https://hub.docker.com/repository/docker/szpaczyn/logstash-arm64)
- [elastic-curator](https://hub.docker.com/repository/docker/szpaczyn/elasticsearch-curator)
- [xbrowsersync](https://hub.docker.com/repository/docker/szpaczyn/xbrowsersync)

## Helm

> <https://szpaczyna.github.io/rpi-k3s>

<!--START_SECTION_LINES_OF_CODE:readme-info-->

<!--END_SECTION_LINES_OF_CODE:readme-info-->

## TODO

- Automation
- Logging (partially done)
- Wazuh (security stuff)
- Zalando postgres operator
