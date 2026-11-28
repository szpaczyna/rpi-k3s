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

The chart exposes `media.lan.shpaq.org` through an `HTTPRoute` in
`templates/httproute.yaml`, attached to `traefik-internal-gateway`. The chart
has no `Certificate`; TLS comes from the shared `wildcard-lan-tls` Secret (see
[`cluster/helm/traefik-internal`](../traefik-internal)).

| Path | Target |
|---|---|
| `/` (exact) | `landingpage` pod (`templates/landingpage.yaml`) when `landingPage.enabled`, otherwise a 302 to `https://shpaq.org/` |
| `/transmission`, `/<app>` for each enabled `media.<app>` | the app's Service, `PathPrefix` match |
| anything else | 302 back to `https://media.lan.shpaq.org/` |

Every rule carries `security-chain-internal` (a `redirect-https` chain) and
`authelia` (forwardAuth). Authelia asks for one factor from `10.0.0.0/24` and two
factors from anywhere else. Its session cookie is scoped to `.shpaq.org`, so it
covers `media.lan.shpaq.org`. `https://media.home/` answers with a 301 to the same
path on `media.lan.shpaq.org` (see [`cluster/helm/traefik-internal`](../traefik-internal)).

## Authentication

Authelia is the only login for the web UIs. Each app keeps its API key, and
exportarr, homepage widgets and Prowlarr call the apps by Service URL
(`http://<app>.media:<port>`), which bypasses Traefik and Authelia.

| App | App-side auth | Set by |
|---|---|---|
| radarr, sonarr, lidarr, prowlarr | `External` | `<APP>__AUTH__METHOD` in `media.<app>.env` |
| readarr (bookshelf) | `External` | `READARR__AUTH__METHOD`; the fork keeps Readarr's `Readarr:Auth` config section |
| bazarr | `None` | by hand, see below |
| transmission | off | `USER`/`PASS` unset; `WHITELIST` and `HOST_WHITELIST` in `templates/transmission-deployment.yaml` |

Bazarr has no external auth mode and no environment override for it. After the
first deploy with Authelia in front, open Bazarr, go to Settings, General,
Security, set Authentication to `None` and save. The setting lives in
`/config/config/config.yaml` on the `bazarr` PVC, so it survives restarts.

Transmission runs with RPC authentication disabled. `WHITELIST` admits
`127.0.0.1`, `::1` (the exporter sidecar) and the pod CIDR `10.42.*.*` (Traefik
and the *arr download clients). `HOST_WHITELIST` admits the `transmission-http`
Service names and `httpRoute.hostname`; Transmission returns 421 for any other
`Host` header.

The landing page links are generated from `.Values.media`. Disabling an app
removes its link without a template change.
