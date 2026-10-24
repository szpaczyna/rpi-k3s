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
moved to `~/git/k3s-old-stuff` (see that repo).

## Uninstallation

To uninstall the media stack, run:

```bash
helm uninstall <release-name>
```

## Notes

- Ensure that your Kubernetes cluster has sufficient resources to run all the applications.

For more information on each application, refer to their respective documentation.

## Ingress / Routing

The chart exposes `media.home` through an `HTTPRoute` in `templates/httproute.yaml`,
attached to `traefik-internal-gateway`. The chart has no `Certificate`; TLS comes
from the shared `wildcard-home-tls` Secret (see
[`cluster/helm/traefik-internal`](../traefik-internal)).

| Path | Target |
|---|---|
| `/` (exact) | `landingpage` pod (`templates/landingpage.yaml`) when `landingPage.enabled`, otherwise a 302 to `https://shpaq.org/` |
| `/transmission`, `/<app>` for each enabled `media.<app>` | the app's Service, `PathPrefix` match |
| anything else | 302 back to `https://media.home/` |

Every route carries `security-chain-internal`, a `redirect-https` chain with no
Authelia. An Authelia cookie is scoped to `.shpaq.org`, so it never reaches
`media.home`.

The landing page links are generated from `.Values.media`. Disabling an app
removes its link without a template change.
