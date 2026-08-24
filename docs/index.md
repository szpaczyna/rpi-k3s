---
layout: default
---

## Workloads

- Apps/Helm Charts:
  - [bitwarden](cluster/helm/bitwarden) - Passwords Management
  - [gitea](cluster/helm/gitea) - Git with a cup of tea
  - [pihole](cluster/helm/pihole) - DNS ad-blocker
  - [postgresql](cluster/helm/postgresql) - PostgreSQL database
  - [version-checker](cluster/helm/version-checker) - Checker for newest version of deployed apps
  - [shpaq-org](cluster/helm/shpaq-org) - Personal website
  - [pihole](cluster/helm/pihole) - DNS ad-blocker
  - [speedtest](cluster/helm/speedtest) - Prometheus speedtest exporter
  - [media-stack](cluster/helm/media-stack) - Transmission, Radarr, Sonarr, Lidarr, Prowlarr, Readarr, Bazarr
  - [grafana](cluster/helm/grafana) - Grafana (for dashboards)

- Apps/YAML:
  - [speedtest](cluster/apps/speedtest.yaml) - Prometheus speedtest exporter

- Retired (`cluster/helm/unused/`):
  - [calibre](cluster/helm/unused/calibre) - Calibre-Web e-book server (extracted from media-stack)
  - [event-exporter](cluster/helm/unused/event-exporter) - Kubernetes events exporter
  - [gentoo](cluster/helm/unused/gentoo) - cross-compiler (helm chart, plain manifests in [gentoo-manifests](cluster/helm/unused/gentoo-manifests))
  - [ingress-nginx](cluster/helm/unused/ingress-nginx) - legacy ingress controller, replaced by Traefik
  - [influxdb](cluster/helm/unused/influxdb) - Database for Apple Health exports
  - [kanboard](cluster/helm/unused/kanboard) - Kanban project management software
  - [nextcloud](cluster/helm/unused/nextcloud) - Personal cloud service
  - [openweather-exporter](cluster/helm/unused/openweather) - OpenWeather API exporter

- System:
  - [prometheus](cluster/helm/prometheus) - Prometheus monitoring system
  - [cert-manager](cluster/helm/cert-manager) - Automated letsencrypt broker
  - [metallb](cluster/core/networking) - Load-balancer for bare-metal with BGP
  - [longhorn](cluster/helm/longhorn) - Distributed storage system
  - [traefik](cluster/helm/traefik) - Ingress controller (Gateway API / HTTPRoute)
  - [x509-certificate-exporter](cluster/helm/x509-certificate-exporter) - Certificates monitoring
  - [loki](cluster/helm/loki) - Log aggregation system
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
