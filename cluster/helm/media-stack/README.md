# Media Stack Helm Chart

This Helm chart deploys a media application stack on Kubernetes, including popular applications such as Bazarr, Lidarr, Prowlarr, Radarr, Readarr, Sonarr, and Transmission.

## Prerequisites

- Kubernetes cluster (v1.16+)
- Helm (v3.0+)

## Installation

To install the media stack Helm chart, follow these steps:

1. **Add the Helm repository (if applicable)**:

   ```bash
   helm repo add <repository-name> <repository-url>
   ```

2. **Install the chart**:

   ```bash
   helm install <release-name> ./media-stack-helm \
     --set global.timezone="Europe/Warsaw" \
     --set global.runAsUser=568 \
     --set global.runAsGroup=568
   ```

3. **Verify the installation**:

   ```bash
   helm list
   ```

## Configuration

This chart uses a simplified values structure:

- `images:` central map of image repository/tag per app (radarr/sonarr/lidarr/prowlarr/readarr/bazarr/transmission/exportarr).
- `media:` per-service blocks with `enable: true|false` and `service.port`.
- `global:` for timezone, runAsUser/runAsGroup, resources and nodeSelector.

Example (see `values.yaml`):

```yaml
images:
   radarr:
      repository: lscr.io/linuxserver/radarr
      tag: latest

media:
   radarr:
      enable: true
      service:
         port: 7878

global:
   timezone: Europe/Warsaw
   runAsUser: 568
   runAsGroup: 568
```

When `media.<name>.enable` is true and the name ends with "arr", the chart will render a Deployment + Service using the centralized `images` map.

Transmission keeps its specialized template and is enabled via `transmission.enable`.

Calibre-Web was extracted into its own standalone chart; it is currently
retired and lives in `cluster/helm/unused/calibre`.

## Uninstallation

To uninstall the media stack, run:

```bash
helm uninstall <release-name>
```

## Notes

- Ensure that your Kubernetes cluster has sufficient resources to run all the applications.

For more information on each application, refer to their respective documentation.

## Ingress / Routing

Routing is exposed via a Gateway API `HTTPRoute` (see
`templates/httproute.yaml`), attached to `traefik-internal-gateway` (see
[`cluster/helm/traefik-internal`](../traefik-internal)). This chart is LAN-only:
it is not reachable from the WAN and carries no `Certificate` of its own, since
`traefik-internal` terminates TLS for every `*.home` name with the single
`wildcard-home-tls` Secret.

All app paths (`/transmission`, `/bazarr`, `/lidarr`, `/prowlarr`, `/radarr`,
`/readarr`, `/sonarr`) run through `security-chain-internal`, a `redirect-https`
chain only. There is no Authelia on this route: `*.home` is LAN-trusted, and
an Authelia cookie issued for `.shpaq.org` would not be sent to `media.home`.
Booklore is unaffected and stays behind `security-chain` + Authelia on the
external gateway.

A bare request to `https://media.home/` (no app path) serves the landing page
pod (`templates/landingpage.yaml`), which lists the enabled apps and links to
each. The links are derived from `.Values.media`, so disabling an app removes
it from the page without editing the template. Any other unmatched path is
redirected (302) back to `media.home/`.
