<img src="assets/rpi.png" alt="Raspberry Pi logo" align="left" width="144px" height="144px"/>

<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="font-size: 2em; font-weight: bold;">rpi-k3s</span>
<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="font-size: 1.3em; font-weight: normal;">Home Cloud on Raspberry Pi(s)</span>
<br>
<br>
<p>
  <a href="https://github.com/szpaczyna/rpi-k3s/actions/workflows/lint-all.yml">
    <img src="https://github.com/szpaczyna/rpi-k3s/actions/workflows/lint-all.yml/badge.svg" alt="Lint & Validate" />
  </a>
  <a href="https://github.com/szpaczyna/rpi-k3s/actions/workflows/release.yml">
    <img src="https://github.com/szpaczyna/rpi-k3s/actions/workflows/release.yml/badge.svg" alt="Release Please" />
  </a>
</p>

<!--START_SECTION_PROFILE_VIEWS:readme-info-->

<!--END_SECTION_PROFILE_VIEWS:readme-info-->

* * *

## Cluster

| | |
|---|---|
| **K3s** | v1.35.3+k3s1 |
| **OS** | Ubuntu 24.04.4 LTS (arm64) |
| **Nodes** | 1 master + 3 workers |

* * *

## Workloads

### Helm Installed Apps

| App | Description |
|-----|-------------|
| [bitwarden](cluster/helm/bitwarden) | Password management (Vaultwarden) |
| [booklore](cluster/helm/booklore) | Book library management |
| [gitea](cluster/helm/gitea) | Self-hosted Git service |
| [kanboard](cluster/helm/kanboard) | Kanban project management |
| [nextcloud](cluster/helm/nextcloud) | Personal cloud service |
| [media-stack](cluster/helm/media-stack) | Radarr, Sonarr, Lidarr, Prowlarr, Readarr, Bazarr, Transmission |
| [shpaq-org](cluster/helm/shpaq-org) | Personal website |
| [whoops](cluster/helm/whoops) | Whoop fitness data dashboards |
| [influxdb](cluster/helm/influxdb) | Time-series DB (Apple Health exports) |
| [postgresql](cluster/helm/postgresql) | PostgreSQL database (HA) |

### Apps (YAML/Kustomize)

| App | Description |
|-----|-------------|
| [gentoo](cluster/apps/gentoo) | Cross-compiler and playground |
| [pihole](cluster/apps/pihole) | DNS ad-blocker (ingress proxy) |
| [speedtest](cluster/apps/speedtest) | Prometheus speedtest exporter |

### Monitoring & Observability

| App | Description |
|-----|-------------|
| [prometheus](cluster/helm/prometheus) | Monitoring and alerting |
| [grafana](cluster/helm/grafana) | Dashboards and visualization |
| [loki](cluster/helm/loki) | Log aggregation (+ Fluent Bit) |
| [event-exporter](cluster/helm/event-exporter) | Kubernetes events exporter |
| [x509-certificate-exporter](cluster/helm/x509-certificate-exporter) | TLS certificate expiry monitoring |
| [openweather-exporter](cluster/helm/openweather) | OpenWeather API metrics |
| [unifipoller](cluster/helm/unifipoller) | UniFi network metrics exporter |
| [version-checker](cluster/helm/version-checker) | Deployed image version monitoring |

### System / Infrastructure

| Component | Description |
|-----------|-------------|
| [cert-manager](cluster/helm/cert-manager) | Automated Let's Encrypt certificates |
| [metallb](cluster/helm/metallb) | Bare-metal load balancer (BGP) |
| [ingress-nginx](cluster/helm/ingress-nginx) | Ingress controller |
| [longhorn](cluster/helm/longhorn) | Distributed block storage |
| [local-path-provisioner](cluster/helm/local-path-provisioner) | Local HostPath storage provisioner |
| [system-upgrade-controller](cluster/core/system-upgrade-controller) | Automated K3s upgrades |
| [renovate](cluster/core/renovate) | Automated dependency updates (CronJob) |

* * *

## Repository Structure

```text
cluster/
  apps/          # Raw YAML / Kustomize applications
  backup/        # Backup CronJobs and Velero config
  core/          # Namespaces, system-upgrade-controller, renovate
  helm/          # Helm charts and deploy scripts
scripts/         # Utility scripts (gitea mirrors, monitoring, setup)
assets/          # Logos and images
.github/         # CI workflows (lint-all, release-please)
```

* * *

## CI/CD

| Workflow | Purpose |
|----------|---------|
| [lint-all](.github/workflows/lint-all.yml) | YAML lint, Markdown lint, ShellCheck, Kubeconform, Kube-linter, Chart Testing |
| [release](.github/workflows/release.yml) | Release Please (automated versioning) |
| [readme_append](.github/workflows/readme_append.yml) | README metadata updates |

* * *

<!--START_SECTION_LINES_OF_CODE:readme-info-->

<!--END_SECTION_LINES_OF_CODE:readme-info-->

## :handshake: Thanks

A lot of inspiration for my cluster came from the people that have shared their
clusters over at [awesome-home-kubernetes].

[awesome-home-kubernetes]: https://github.com/k8s-at-home/awesome-home-kubernetes
