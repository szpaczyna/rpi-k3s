# Calibre-Web

Retired and not deployed. This chart lives in `unused/`, nothing runs it, and
`enabled: false` in `values.yaml` makes it render no resources.

It was the Calibre-Web e-book server in the `media` namespace.
[Booklore](../../booklore) replaced it.

## What it was

| Item | Value |
|---|---|
| Image | `lscr.io/linuxserver/calibre-web:0.6.27` |
| Route | `calibre.shpaq.org` through `traefik-gateway` |
| Namespace | `media` |
| Service | ClusterIP, port `8083` |
| Storage | 1 Gi Longhorn PVC for app config, `library/books` from the shared `media` volume |

The chart's `Chart.yaml` describes it as extracted from `media-stack`.

## What replaced it

Booklore took over the e-book library. Commit `92281c1` (Dec 28, 2025) added it
with the message "booklore as a calibre replacement". Booklore runs in `media`
at `booklore.shpaq.org`.

This chart moved to `unused/` in commit `5d8e42e` (Aug 22, 2026). That commit
records no reason for the move.

## Why it was retired

The commit history states no reason. The Renovate config
(`cluster/helm/renovate/values.yaml`, commit `e60025f`) records that the
calibre-web 5.x tags are amd64-only and cannot run on this arm64 cluster. That
note covers the 5.x line only. The repo does not record the architecture of the
pinned 0.6.27 tag.

## Reviving it

Reviving the chart is a decision, not a README task. The gate and the revival
checklist sit at the top of `values.yaml`.

The `security-chain` middleware in `media` has no Authelia layer. `media` left
`autheliaNamespaces` in `cluster/helm/middlewares/values.yaml`, so a revived
route would rely on Calibre-Web's own login.

## Related

- [booklore](../../booklore): the live replacement in `media`.
- [traefik-external](../../traefik-external): the `calibre-shpaq-org-tls` certificate ref is commented out.
- [media-stack](../../media-stack): the former home of this chart.
