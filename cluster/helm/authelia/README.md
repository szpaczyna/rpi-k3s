# Authelia

Single Sign-On / MFA portal for `*.shpaq.org` subdomains, deployed using
the upstream chart `authelia/authelia` (0.11.22, image pinned to 4.39.28) from
`https://charts.authelia.com`.

## Files

| File | Description |
|---|---|
| `values-public.yaml` | Non-sensitive chart config (image, pod, ingress, storage, initContainer) |
| `deploy` | Deploy script (repo + secrets + `helm upgrade --install`) |
| `./values.enc.yaml` | Sensitive config (session, access_control, TOTP, WebAuthn, password policy) — SOPS encrypted |
| `./secrets.enc.yaml` | Kubernetes Secrets (JWT/session/storage keys + `users_database.yml`) — SOPS encrypted |

## Who this protects

- WAN: `whoops.shpaq.org`.
- LAN: the web UIs under `*.lan.shpaq.org` (media stack, homepage, Pi-hole,
  Prometheus, Longhorn and both Traefik dashboards).

The session cookie is issued for `shpaq.org`, so one login at `auth.shpaq.org`
covers both groups. Grafana has no forwardAuth and is due to log in through
Authelia OIDC. Loki has no forwardAuth because the host log shippers cannot
log in; the `lan-only` Middleware limits its route to `10.0.0.0/24`.

## Architecture

- **Gateway API**: HTTPRoute for `auth.shpaq.org` → Gateway `traefik-gateway`
  (external), defined in `extraObjects` with the `security-chain` Middleware
  (geoblock, HSTS). There is no counterpart on `traefik-internal`.
- **Authentication backend**: file-based (`users_database.yml`), seeded from
  Secret `authelia-users` to PVC via initContainer — file is writable, password
  changes from the portal work.
- **Storage**: SQLite (`/config/db.sqlite3`) on PVC `authelia` (1 Gi) backed by
  `storageClass: longhorn`.
- **Secrets**: Secret `authelia` mounted as `secret.existingSecret`; chart sets
  `AUTHELIA_*_FILE` env vars pointing to mounted key files.
- **Session**: cookie `authelia_session`, domain `shpaq.org`, subdomain `auth`,
  24h / 5min / 30d.
- **Notifier**: filesystem (`/config/notification.txt`) — read OTPs via:
  ```
  kubectl -n auth exec deploy/authelia -- cat /config/notification.txt
  ```
- **2FA**: TOTP (issuer `shpaq.org`) + WebAuthn (passkeys enabled).
- **Access control** (`default_policy: deny`): `auth.shpaq.org` bypasses.
  `*.lan.shpaq.org` and `whoops.shpaq.org` need one_factor from the `lan`
  network (`10.0.0.0/24`, under `definitions.network`) and two_factor from
  anywhere else. The earlier bypass from `10.0.0.0/8` also matched the pod
  CIDR `10.42.0.0/16`, so any pod could reach a protected app without a login.


## Deployment

    cd cluster/helm/authelia
    ./deploy

The script:
1. Adds the `authelia` Helm repo
2. Applies Kubernetes Secrets from `./secrets.enc.yaml` (via `sops -d`)
3. Runs `helm upgrade --install` with both `values-public.yaml` and
   `./values.enc.yaml` (via `sops -d`)

**Important**: the `authelia` and `security-chain` Middleware objects are
**not** owned by this chart. They come from [`cluster/helm/middlewares`](../middlewares),
because an HTTPRoute `extensionRef` must name a Middleware in its own
namespace. Deploy that chart first when
adding a namespace.

## Secrets

Both secrets live next to the chart (this directory, SOPS-encrypted).
To edit:

    sops ./values.enc.yaml
    sops ./secrets.enc.yaml

To view without editing:

    sops -d ./values.enc.yaml
    sops -d ./secrets.enc.yaml

## First login

1. Open `https://auth.shpaq.org`
2. Log in with the temporary password (see `secrets.enc.yaml`)
3. **Change password** in the portal (Settings → Change Password) — written to
   `/config/users_database.yml` on PVC
4. Register 2FA (TOTP)

## Secret rotation

1. Update values in `./values.enc.yaml` (or `secrets.enc.yaml` for keys)
2. Apply: `./deploy`
3. Restart deployment (chart does not auto-restart on `existingSecret` change):
   ```
   kubectl -n auth rollout restart deploy/authelia
   ```

## Verification

    kubectl -n auth get deploy,pvc,httproute,svc
    kubectl -n auth logs deploy/authelia

Check that:
- initContainer copied `users_database.yml` to PVC
- container is `Ready` (probes `/api/health`)
- HTTPRoute for `auth.shpaq.org` is attached to `traefik-gateway`
- an unauthenticated request to `whoops.shpaq.org` redirects to the portal
