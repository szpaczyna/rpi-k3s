# Booklore

[Booklore](https://github.com/booklore-app/booklore) is a self-hosted book
library manager (covers, metadata, e-book serving). Deployed as a Helm chart
(`appVersion 1.18.5`).

## Deployment

    cd cluster/helm/booklore
    ./deploy

The script:

1. Applies the SOPS-encrypted DB secret from `./db-secret.enc.yaml`
   (via `sops -d`)
2. Runs `helm upgrade --install` with `values.yaml`

Namespace: `media`.

## Files

| File | Description |
|---|---|
| `values.yaml` | Non-sensitive chart config (image, securityContext, persistence, probes) |
| `db-secret.enc.yaml` | SOPS-encrypted MariaDB password secret |
| `deploy` | Deploy script (secret + `helm upgrade --install`) |

## Architecture

- **App container** (`szpaczyn/booklore`) — the Booklore backend, using
  HTTPRoute `booklore.shpaq.org` → `traefik-gateway`.
- **Inline MariaDB** (`lscr.io/linuxserver/mariadb`) — runs as a second
  container in the same pod, using the `booklore-db-secret` for credentials.
- **Storage** (persistence, existing PVCs):
  - `booklore-data` → `/app/data`
  - `media` (subPath `library/books`) → `/books`
  - `booklore-mariadb-config` → MariaDB config
- **Pod security**:
  - `podSecurityContext`: `fsGroup 568`
  - container `securityContext`: `allowPrivilegeEscalation: false`, drops
    `ALL`, re-adds only a minimal allowed capability set (`CHOWN`,
    `DAC_OVERRIDE`, `SETUID`, `NET_BIND_SERVICE`, ...). `NET_RAW` is
    intentionally **not** added (dropped) so the `drop-net-raw-capability`
    kube-linter check passes.

## Secrets

The DB password lives in `./db-secret.enc.yaml` (SOPS-encrypted, next to the
chart). To edit:

    sops ./db-secret.enc.yaml

To view without editing:

    sops -d ./db-secret.enc.yaml

After changing the secret, run `./deploy` and roll the pod if needed:

    kubectl -n media rollout restart deploy/booklore

## Verification

    kubectl -n media get deploy,pvc,httproute,svc
    kubectl -n media get pods -l app.kubernetes.io/name=booklore
