# Authelia

Single Sign-On / MFA portal for `*.shpaq.org` subdomains, deployed using
the upstream chart `authelia/authelia` (0.11.22, appVersion 4.39.24) from
`https://charts.authelia.com`.

## Files

| File | Description |
|---|---|
| `values-public.yaml` | Non-sensitive chart config (image, pod, ingress, storage, initContainer) |
| `deploy` | Deploy script (repo + secrets + `helm upgrade --install`) |
| `./values.enc.yaml` | Sensitive config (session, access_control, TOTP, WebAuthn, password policy) — SOPS encrypted |
| `./secrets.enc.yaml` | Kubernetes Secrets (JWT/session/storage keys + `users_database.yml`) — SOPS encrypted |

## Who this protects

Exactly one route: **`whoops.shpaq.org`**, on the external gateway. That is
the whole consumer list.

The `*.home` domain is deliberately outside this system. `media`, `grafana`,
`prometheus` and `longhorn` all moved to `*.home` behind
`traefik-internal` during the 2026-10-18 migration (PRs #263, #264) and carry
no Authelia. That is not an oversight: the session cookie is issued for
domain `shpaq.org`, and a browser does not send a `.shpaq.org` cookie to
`media.home`. Reusing this single instance for `*.home` would need a second
Authelia with its own cookie domain and an `auth.home` portal. The LAN is
trusted instead, so `*.home` apps are either unauthenticated or carry their
own login.

Two places still name the retired hosts and are safe to ignore for now:

- `values.enc.yaml` `access_control` lists `media.shpaq.org`,
  `calibre.shpaq.org`, `longhorn.shpaq.org` and `prometheus.shpaq.org`
  alongside `whoops.shpaq.org`. Only `whoops.shpaq.org` still resolves; the
  other four have no route and no DNS record, so their rules match nothing.
  Removing them is safe but is a separate cleanup.
- `cluster/helm/middlewares/values.yaml` `autheliaNamespaces` holds a single
  entry, `apps`. It exists to render one `authelia` Middleware per namespace
  rather than in all four, so it would remain a one-line list even with a
  single consumer.

If the WAN route count ever drops to zero, the cheaper move is `basicAuth`
per app and retiring this chart, not keeping an SSO portal for one hostname.

## Architecture

- **Gateway API**: HTTPRoute for `auth.shpaq.org` → Gateway `traefik-gateway`
  (external). There is no counterpart on `traefik-internal`.
- **Authentication backend**: file-based (`users_database.yml`), seeded from
  Secret `authelia-users` to PVC via initContainer — file is writable, password
  changes from the portal work.
- **Storage**: SQLite (`/config/db.sqlite3`) on PVC `authelia` (1 Gi) backed by
  `storageClass: longhorn`.
- **Secrets**: Secret `authelia` mounted as `secret.existingSecret`; chart sets
  `AUTHELIA_*_FILE` env vars pointing to mounted key files.
- **Session**: cookie `authelia_session`, domain `shpaq.org`, subdomain `auth`,
  24h / 5min / 30d. The single-domain cookie is why `*.home` cannot use it.
- **Notifier**: filesystem (`/config/notification.txt`) — read OTPs via:
  ```
  kubectl -n auth exec deploy/authelia -- cat /config/notification.txt
  ```
- **2FA**: TOTP (issuer `shpaq.org`) + WebAuthn (passkeys enabled).
- **Access control** (`default_policy: deny`):
  - `auth.shpaq.org` → bypass
  - the five `*.shpaq.org` app names → bypass from `10.0.0.0/8`, otherwise
    `two_factor`. See the note above: only `whoops.shpaq.org` is live.


## Deployment

    cd cluster/helm/authelia
    ./deploy

The script:
1. Adds the `authelia` Helm repo
2. Applies Kubernetes Secrets from `./secrets.enc.yaml` (via `sops -d`)
3. Runs `helm upgrade --install` with both `values-public.yaml` and
   `./values.enc.yaml` (via `sops -d`)

**Important**: the `authelia` Middleware objects are **not** owned by this
chart. They are rendered by [`cluster/helm/middlewares`](../middlewares) from
its `autheliaNamespaces` list, because a `forwardAuth` reference must live in
the same namespace as the HTTPRoute that uses it. So deploying this chart
does not create them; deploy `middlewares` first when adding a namespace.

There is no `authelia` Middleware in namespace `auth`: `auth` is not on any
list in that chart, because `auth.shpaq.org` serves the portal directly and
never goes through `forwardAuth`.

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

To confirm the one route that depends on this is wired up:

    kubectl get middleware -n apps authelia -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}'
    kubectl get httproute -n apps whoops -o jsonpath='{.spec.rules[0].filters[0].extensionRef.name}'

Both should show `middlewares` and `authelia`.

A plain `curl -sI https://whoops.shpaq.org/` from a workstation is **not** a
reliable check. It can answer 200 without ever reaching `forwardAuth`, because
the response header `server: waitress` is whoops' own WSGI server rather than
a denial from Authelia. Check the log instead:

    kubectl -n auth logs deploy/authelia --tail=50 | grep forward-auth

An anonymous WAN request is logged as a 302 to
`https://auth.shpaq.org/?rd=https%3A%2F%2Fwhoops.shpaq.org%2F`, which is the
proof that `forwardAuth` is still in the path. Errors like
`header 'X-Forwarded-Method' is empty` come from probes that hit the Authelia
endpoint directly, not from Traefik.

Check that:
- initContainer copied `users_database.yml` to PVC
- container is `Ready` (probes `/api/health`)
- HTTPRoute for `auth.shpaq.org` is attached to `traefik-gateway`
