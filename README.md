<img src="assets/rpi.png" align="left" width="144px" height="144px"/>

<!--img src="https://raspbernetes.github.io/img/logo.svg" align="left" width="144px"
height="144px"/-->

<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="font-size: 2em; font-weight: bold;">rpi-k3s</span>
<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="font-size: 1.3em; font-weight: normal;">Home Cloud on Raspberry Pie(s)</span>
<br>
<br>

<!--START_SECTION_PROFILE_VIEWS:readme-info-->

<!--END_SECTION_PROFILE_VIEWS:readme-info-->

* * *

## Workloads

- Apps/Helm Charts:
  - [bitwarden](cluster/helm/bitwarden) - Passwords Management
  - [gitea](cluster/helm/gitea) - Git with a cup of tea
  - [kanboard](cluster/helm/kanboard) - Kanban project management software
  - [nextcloud](cluster/helm/nextcloud) - Personal cloud service
  - [photoprism](cluster/helm/photoprism) - Photos management
  - [postgresql](cluster/helm/postgresql) - PostgreSQL database
  - [version-checker](cluster/helm/version-checker) - Checker for newest version of deployed apps
  - [influxdb](cluster/helm/influxdb) - Database for Apple Health exports
  - [shpaq-org](cluster/helm/shpaq-org) - Personal website
  - [media-stack](cluster/helm/media-stack) - Transmission, Radarr, Lidarr, Sonarr, Bazarr, Jackett, Calibre-web
  
- Apps/YAML:
  - [unifi](cluster/apps/unifi) - Unifi controller/prometheus poller
  - [grafana](cluster/apps/monitoring/grafana) - Grafana with some provisioned dashboards
  - [gentoo](cluster/apps/gentoo) - cross-compiler and playground

- System:
  - [prometheus](cluster/helm/prometheus) - Prometheus monitoring system
  - [cert-manager](cluster/core/cert-manager) - Automated letsencrypt broker
  - [metallb](cluster/core/networking) - Load-balancer for bare-metal with BGP
  - [longhorn](cluster/helm/longhorn) - Distributed storage system
  - [ingress-nginx](cluster/helm/ingress-nginx) - Ingress controller
  - [x509-certificate-exporter](cluster/helm/x509-certificate-exporter) - Certificates monitoring
  - [openweather-exporter](cluster/helm/openweather) - OpenWeather API exporter
  - [loki](cluster/helm/loki) - Log aggregation system
  - [event-exporter](cluster/helm/event-exporter) - Kubernetes events exporter
  - [local-path-provisioner](cluster/helm/local-path-provisioner) - Local storage provisioner


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


# test
