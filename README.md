<img src="assets/rpi.png" alt="Raspberry Pi logo" align="left" width="144px" height="144px"/>

<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="font-size: 2em; font-weight: bold;">rpi-k3s</span>
<br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="font-size: 1.3em; font-weight: normal;">Home Cloud on Raspberry Pi(s)</span>
<br>
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
| **K3s** | v1.36.3+k3s1 |
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
| [media-stack](cluster/helm/media-stack) | Radarr, Sonarr, Lidarr, Prowlarr, Readarr, Bazarr, Transmission |
| [pihole](cluster/helm/pihole) | DNS ad-blocker |
| [shpaq-org](cluster/helm/shpaq-org) | Personal website |
| [speedtest](cluster/helm/speedtest) | Prometheus speedtest exporter |
| [whoops](cluster/helm/whoops) | Whoop fitness data dashboards |
| [postgresql](cluster/helm/postgresql) | PostgreSQL database (HA) |

### Retired / Not Currently Deployed

Charts kept in `cluster/helm/unused/` for future use but not installed
on the cluster right now. Revival steps are documented in each chart's
`values.yaml`/`deploy`.

| App | Description |
|-----|-------------|
| [calibre](cluster/helm/unused/calibre) | Calibre-Web e-book server (extracted from media-stack) |
| [event-exporter](cluster/helm/unused/event-exporter) | Kubernetes events exporter |
| [gentoo](cluster/helm/unused/gentoo) | Gentoo cross-compiler (helm chart; plain manifests in `gentoo-manifests`) |
| [ingress-nginx](cluster/helm/unused/ingress-nginx) | Legacy ingress controller, replaced by Traefik |
| [influxdb](cluster/helm/unused/influxdb) | Time-series DB (Apple Health exports) |
| [kanboard](cluster/helm/unused/kanboard) | Kanban project management |
| [nextcloud](cluster/helm/unused/nextcloud) | Personal cloud service |
| [openweather-exporter](cluster/helm/unused/openweather) | OpenWeather API metrics |

### Monitoring & Observability

| App | Description |
|-----|-------------|
| [prometheus](cluster/helm/prometheus) | Monitoring and alerting |
| [grafana](cluster/helm/grafana) | Dashboards and visualization |
| [loki](cluster/helm/loki) | Log aggregation (+ Fluent Bit) |
| [x509-certificate-exporter](cluster/helm/x509-certificate-exporter) | TLS certificate expiry monitoring |
| [unifipoller](cluster/helm/unifipoller) | UniFi network metrics exporter |
| [version-checker](cluster/helm/version-checker) | Deployed image version monitoring |

### System / Infrastructure

| Component | Description |
|-----------|-------------|
| [cert-manager](cluster/helm/cert-manager) | Automated Let's Encrypt certificates (ACME HTTP-01 via Gateway API) |
| [metallb](cluster/helm/metallb) | Bare-metal load balancer (L2) |
| [traefik](cluster/helm/traefik) | Ingress controller (Gateway API / HTTPRoute) |
| [gateway-api](cluster/core/gateway-api) | Kubernetes Gateway API CRDs |
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

### Secrets

Sensitive values are SOPS-encrypted and live **next to each application** in
its own chart directory (e.g. `cluster/helm/<app>/*.enc.yaml`) rather than in
a central location. Each chart's `deploy` script decrypts and applies its own
secrets (`sops -d ./<file>.enc.yaml`) before running the Helm upgrade. To work
with a secret, decrypt/encrypt in place with `sops` inside that directory:

```bash
cd cluster/helm/<app>
sops ./<file>.enc.yaml        # edit
sops -d ./<file>.enc.yaml     # view without editing
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
