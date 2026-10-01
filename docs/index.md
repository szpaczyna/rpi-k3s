---
layout: default
---

## Workloads

- Helm Installed Apps:
  - [bitwarden](cluster/helm/bitwarden) - Password management (Vaultwarden)
  - [booklore](cluster/helm/booklore) - Book library management
  - [gitea](cluster/helm/gitea) - Self-hosted Git service
  - [media-stack](cluster/helm/media-stack) - Radarr, Sonarr, Lidarr, Prowlarr, Readarr, Bazarr, Transmission
  - [pihole](cluster/helm/pihole) - DNS ad-blocker
  - [shpaq-org](cluster/helm/shpaq-org) - Personal website
  - [speedtest](cluster/helm/speedtest) - Prometheus speedtest exporter
  - [whoops](cluster/helm/whoops) - Whoop fitness data dashboards
  - [postgresql](cluster/helm/postgresql) - PostgreSQL database (HA)

- Retired / Not Currently Deployed (`cluster/helm/unused/`):
  - [calibre](cluster/helm/unused/calibre) - Calibre-Web e-book server (extracted from media-stack)
  - [event-exporter](cluster/helm/unused/event-exporter) - Kubernetes events exporter
  - [gentoo](cluster/helm/unused/gentoo) - Gentoo cross-compiler (helm chart; plain manifests in [gentoo-manifests](cluster/helm/unused/gentoo-manifests))
  - [ingress-nginx](cluster/helm/unused/ingress-nginx) - Legacy ingress controller, replaced by Traefik
  - [influxdb](cluster/helm/unused/influxdb) - Time-series DB (Apple Health exports)
  - [kanboard](cluster/helm/unused/kanboard) - Kanban project management
  - [nextcloud](cluster/helm/unused/nextcloud) - Personal cloud service
  - [openweather-exporter](cluster/helm/unused/openweather) - OpenWeather API metrics

- Monitoring & Observability:
  - [prometheus](cluster/helm/prometheus) - Monitoring and alerting
  - [grafana](cluster/helm/grafana) - Dashboards and visualization
  - [loki](cluster/helm/loki) - Log aggregation (+ Fluent Bit)
  - [x509-certificate-exporter](cluster/helm/x509-certificate-exporter) - TLS certificate expiry monitoring
  - [unifipoller](cluster/helm/unifipoller) - UniFi network metrics exporter
  - [version-checker](cluster/helm/version-checker) - Deployed image version monitoring

- System / Infrastructure:
  - [cert-manager](cluster/helm/cert-manager) - Automated Let's Encrypt certificates (ACME HTTP-01 via Gateway API)
  - [metallb](cluster/helm/metallb) - Bare-metal load balancer (L2)
  - [traefik](cluster/helm/traefik) - Ingress controller (Gateway API / HTTPRoute)
  - [gateway-api](cluster/core/gateway-api) - Kubernetes Gateway API CRDs
  - [longhorn](cluster/helm/longhorn) - Distributed block storage
  - [local-path-provisioner](cluster/helm/local-path-provisioner) - Local HostPath storage provisioner
  - [system-upgrade-controller](cluster/core/system-upgrade-controller) - Automated K3s upgrades
  - [renovate](cluster/core/renovate) - Automated dependency updates (CronJob)

## Helm

> <https://szpaczyna.github.io/rpi-k3s>

<!--START_SECTION_LINES_OF_CODE:readme-info-->

<!--END_SECTION_LINES_OF_CODE:readme-info-->
