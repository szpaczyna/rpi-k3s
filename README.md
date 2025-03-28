<img src="assets/rpi.png" align="left" width="144px" height="144px"/>

<!--img src="https://raspbernetes.github.io/img/logo.svg" align="left" width="144px"
height="144px"/-->

# rpi-k3s

### Home Cloud on Raspberry Pie(s)

<br>
<!--START_SECTION_PROFILE_VIEWS:readme-info-->

<!--END_SECTION_PROFILE_VIEWS:readme-info-->

* * *

## Workloads

- Apps/Helm Charts:

  - [bitwarden](cluster/cluster/helm/bitwarden) - Passwords Management
  - [gitea](cluster/helm/gitea) - Git with a cup of tea
  - [kanboard](cluster/helm/kanboard) - Kanban project management software
  - [nextcloud](cluster/helm/nextcloud) - personal cloud service
  - [photoprism](cluster/helm/photoprism) - photos management
  - [postgresql](cluster/helm/postgresql) - self explanatory
  - [version-checker](cluster/helm/version-checker) - Checker for newest version of deployed apps
  - [influxdb](cluster/helm/influxdb) - Database for Apple Health exports
  - [shpaq-org](cluster/helm/shpaq) - Personal website

- Apps/YAML

  - [unifi](cluster/apps/unifi) - Unifi controller/prometheus poller

  - [grafana](cluster/apps/monitoring/grafana) - Grafana with some provisioned dashboards
  - [media downloads](cluster/apps/media) - jackett, bazarr, radarr, lidarr and sonarr, calibre-web, transmission
  - [gentoo](cluster/apps/gentoo) - cross-compiler and plyground

- System
  - [prometheus](cluster/helm/prometheus) - Prometheus
  - [cert-manager](cluster/core/cert-manager) - Automated letsencrypt broker
  - [metallb](cluster/core/networking) - Load-balancer for bare-metal with BGP
  - [longhorn](cluster/helm/longhorn) - longhorn storage
  - [ingress-nginx](cluster/helm/ingress-nginx) - ingress operator
  - [x509-certificate-exporter](cluster/helm/x509-certificate-exporter) - Certs monitoring
  - [openweather-exporter](cluster/helm/openweather) - Openweather exporter


<!--START_SECTION_LINES_OF_CODE:readme-info-->

<!--END_SECTION_LINES_OF_CODE:readme-info-->

<!--  - [event-exporter](cluster/helm/event-exporter) - exports k8s events to loki
- [cert-exporter](cluster/helm/cert-exporter) - certificates monitoring
- [node-problem-detector](cluster/helm/node-problem-detector) - Node problem detector
- [loki](cluster/helm/loki) - Logs shipper and browser
-->

* * *

## :handshake:  Thanks

A lot of inspiration for my cluster came from the people that have shared their
clusters over at [awesome-home-kubernetes].

[awesome-home-kubernetes]: https://github.com/k8s-at-home/awesome-home-kubernetes
