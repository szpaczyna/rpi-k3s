---
layout: default
---

## Workloads

- Helm Installed Apps:
  - [authelia](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/authelia) - Authentication and SSO portal
  - [bitwarden](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/bitwarden) - Password management (Vaultwarden)
  - [booklore](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/booklore) - Book library management
  - [gitea](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/gitea) - Self-hosted Git service
  - [homepage](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/homepage) - Service dashboard at `homepage.home`
  - [media-stack](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/media-stack) - Radarr, Sonarr, Lidarr, Prowlarr, Readarr, Bazarr, Transmission
  - [pihole](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/pihole) - DNS ad-blocker
  - [shpaq-org](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/shpaq-org) - Personal website
  - [speedtest](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/speedtest) - Prometheus speedtest exporter
  - [whoops](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/whoops) - Whoop fitness data dashboards
  - [postgresql](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/postgresql) - PostgreSQL database (HA)

- Retired / Not Currently Deployed: moved to
  [k3s-old-stuff](https://github.com/szpaczyna/k3s-old-stuff)

- Monitoring & Observability:
  - [prometheus](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/prometheus) - Monitoring and alerting
  - [grafana](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/grafana) - Dashboards and visualization
  - [loki](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/loki) - Log aggregation (+ Fluent Bit)
  - [x509-certificate-exporter](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/x509-certificate-exporter) - TLS certificate expiry monitoring
  - [unifipoller](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/unifipoller) - UniFi network metrics exporter
  - [version-checker](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/version-checker) - Deployed image version monitoring
  - [dockerhub-exporter](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/dockerhub-exporter) - Docker Hub repository metrics exporter

- System / Infrastructure:
  - [cert-manager](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/cert-manager) - Automated Let's Encrypt certificates (ACME HTTP-01 via Gateway API)
  - [defaultbackend](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/defaultbackend) - Catch-all backend for Traefik (bare-IP / unknown host)
  - [gentoo](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/gentoo) - Gentoo distcc build node (cross-compiles on behalf of other hosts)
  - [metallb](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/metallb) - Bare-metal load balancer (L2)
  - [middlewares](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/middlewares) - Traefik middlewares (security chain, authelia)
  - [traefik](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/traefik-external) - Ingress controller (Gateway API / HTTPRoute)
  - [traefik-internal](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/traefik-internal) - Internal Traefik instance for the *.home LAN domain
  - [longhorn](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/longhorn) - Distributed block storage
  - [local-path-provisioner](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/local-path-provisioner) - Local HostPath storage provisioner
  - [system-upgrade-controller](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/system-upgrade-controller) - Automated K3s upgrades
  - [renovate](https://github.com/szpaczyna/rpi-k3s/tree/main/cluster/helm/renovate) - Automated dependency updates
