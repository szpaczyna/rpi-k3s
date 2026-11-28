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

## Single sign-on (Authelia)

Booklore 2.4.0 keeps its OIDC settings in the database and reads no OIDC
environment variables (only `FORCE_DISABLE_OIDC`), so the provider is set up
in the UI. Authelia registers Booklore as the public client `booklore` with
PKCE (see [`cluster/helm/authelia`](../authelia/README.md#openid-connect-provider)).
The backend exchanges the code, so the pod must reach `auth.shpaq.org`.

1. Sign in as a Booklore admin and open Settings (cog icon), then
   `Authentication`.
2. Under OIDC Authentication set:
   - OIDC Enabled: on
   - Provider Name: `Authelia`
   - Client ID: `booklore`
   - Client Secret: empty
   - Issuer URI: `https://auth.shpaq.org`
   - Scope: `openid profile email offline_access`
   - Username Claim: `preferred_username`
   - Email Claim: `email`
   - Display Name Claim: `name`
3. Save. Booklore sends `https://booklore.shpaq.org/oauth2-callback` as the
   redirect URI; the Authelia client allows only that one.

If a bad OIDC setting locks you out, set `FORCE_DISABLE_OIDC=true` on the
container to get the local login back.

## Verification

    kubectl -n media get deploy,pvc,httproute,svc
    kubectl -n media get pods -l app.kubernetes.io/name=booklore
