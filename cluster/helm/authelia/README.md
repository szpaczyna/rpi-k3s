# Authelia

Single Sign-On / MFA portal for `*.shpaq.org` subdomains, deployed using
the upstream chart `authelia/authelia` (0.11.6, appVersion 4.39.20) from
`https://charts.authelia.com`.

## Files

| File | Description |
|---|---|
| `values-public.yaml` | Non-sensitive chart config (image, pod, ingress, storage, initContainer) |
| `deploy` | Deploy script (repo + secrets + `helm upgrade --install`) |
| `./values.enc.yaml` | Sensitive config (session, access_control, TOTP, WebAuthn, password policy) — SOPS encrypted |
| `./secrets.enc.yaml` | Kubernetes Secrets (JWT/session/storage keys + `users_database.yml`) — SOPS encrypted |

## Architecture

- **Gateway API**: HTTPRoute for `auth.shpaq.org` → Gateway `traefik-gateway`.
- **Authentication backend**: file-based (`users_database.yml`), seeded from
  Secret `authelia-users` to PVC via initContainer — file is writable, password
  changes from the portal work.
- **Storage**: SQLite (`/config/db.sqlite3`) on PVC `local-path` (1 Gi).
- **Secrets**: Secret `authelia` mounted as `secret.existingSecret`; chart sets
  `AUTHELIA_*_FILE` env vars pointing to mounted key files.
- **Session**: cookie `authelia_session`, domain `shpaq.org`, 24h / 5min / 30d.
- **Notifier**: filesystem (`/config/notification.txt`) — read OTPs via:
  ```
  kubectl -n auth exec deploy/authelia -- cat /config/notification.txt
  ```
- **2FA**: TOTP (issuer `shpaq.org`) + WebAuthn (passkeys enabled).
- **Access control** (`default_policy: deny`):
  - `auth.shpaq.org` → bypass


## Deployment

    cd cluster/helm/authelia
    ./deploy

The script:
1. Adds the `authelia` Helm repo
2. Applies Kubernetes Secrets from `./secrets.enc.yaml` (via `sops -d`)
3. Runs `helm upgrade --install` with both `values-public.yaml` and
   `./values.enc.yaml` (via `sops -d`)

**Important**: deploy Traefik first if middleware references have changed,
as the `authelia` forwardAuth middleware is created per-namespace by
application charts.

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
