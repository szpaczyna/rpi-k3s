# Traefik

Primary ingress controller for the cluster. Replaces `ingress-nginx`
(retired by the Kubernetes project, best-effort maintenance only until
March 2026, no releases/patches afterwards).

Routes are configured via the **Kubernetes Gateway API** (`HTTPRoute`)
rather than the legacy `Ingress` resource. A single shared `Gateway`
(`traefik-gateway`, namespace `kube-system`) terminates TLS for every
hostname served by the cluster; per-application charts only need to
declare an `HTTPRoute` (or, for upstream charts that support it natively,
set `route.main.enabled` / `httpRoute.enabled` / `httproute.enabled` in
`values.yaml`).

## Topology

- **DaemonSet** (one pod per node) — same HA topology as the previous
  `ingress-nginx` DaemonSet.
- **Service type `LoadBalancer`**, pinned to `10.0.0.40` via
  `service.spec.loadBalancerIP` — this is the same IP `ingress-nginx`
  used, transferred during cutover with zero DNS/router changes.
- Chart: `traefik/traefik` v41.1.1, image pinned to `v3.7.10` (chart's own
  `appVersion` default lags one patch behind).
- Dashboard/API exposed on port `8080` on the same LoadBalancer Service —
  reachable from the local network (e.g. `http://10.0.0.40:8080/dashboard/`)
  but **not** routed to the internet and **not** protected by
  authentication. Keep this LAN-only; do not expose it via an `HTTPRoute`
  without adding a `BasicAuth`/`ForwardAuth` Middleware first.

## Gateway listeners

| Listener | Port | Protocol | Notes |
|---|---|---|---|
| `web` | 80 | HTTP | Global redirect to `websecure` (permanent), replaces the per-Ingress `nginx.ingress.kubernetes.io/ssl-redirect: "true"` annotation that used to be set on every Ingress. |
| `websecure` | 443 | HTTPS | `certificateRefs` lists every TLS Secret currently in use across namespaces (`apps`, `media`, `monitoring`). `mode: Terminate`. |

`certificateRefs` cross-namespace access requires a `ReferenceGrant` in
each target namespace — see `referencegrants.yaml` in this directory
(applied once, covers `apps`, `media`, `monitoring`, `longhorn-system`).

When enabling a currently-disabled app (prometheus, longhorn, nextcloud —
see their respective `values.yaml`), add its TLS secret to
`gateway.listeners.websecure.certificateRefs` here.

## Migration from ingress-nginx — annotation mapping

| nginx annotation | Gateway API / Traefik equivalent |
|---|---|
| `nginx.ingress.kubernetes.io/ssl-redirect: "true"` | Global, via `ports.web.http.redirections.entryPoint` (no longer per-route) |
| `ingressClassName: nginx` | `HTTPRoute.spec.parentRefs` → `traefik-gateway` |
| `nginx.ingress.kubernetes.io/auth-type: basic` + `auth-secret` | Traefik `Middleware` (`traefik.io/v1alpha1`) with `basicAuth.secret`, attached via `HTTPRoute` `filters[].extensionRef` |
| `nginx.ingress.kubernetes.io/whitelist-source-range` | Traefik `Middleware` with `ipAllowList.sourceRange`, attached the same way |
| `nginx.ingress.kubernetes.io/app-root` | `HTTPRoute` rule with exact-match `/` and a `RequestRedirect` filter (`ReplaceFullPath`) |
| ExternalName Service backend | **Not supported** by Traefik's Gateway API provider (unlike its Ingress provider). Use a `ClusterIP` Service + manually managed `Endpoints` instead (see `cluster/apps/pihole`). |

### Known gaps (not ported, accepted)

- **HSTS** (`hsts-preload: true` in the old nginx ConfigMap) — no
  equivalent configured. Would need a `headers` Middleware with
  `stsSeconds`/`stsPreload` attached globally.
- **Brotli/gzip compression** — no `compress` Middleware configured
  anywhere yet.
- **ModSecurity / OWASP CRS (WAF)** — no built-in equivalent in Traefik
  OSS; would require a third-party plugin.

None of these affect auth, redirect, or cert-issuance behavior — only
response compression and defense-in-depth headers.

## Gateway API CRDs

Traefik's Helm chart no longer bundles Gateway API CRDs (removed
upstream since chart v40.2.0). They are installed separately — see
[`cluster/core/gateway-api`](../../core/gateway-api).

## cert-manager integration

Both `letsencrypt-prod` and `letsencrypt-stage` `ClusterIssuer`s use the
`http01.gatewayHTTPRoute` solver (instead of `http01.ingress`), pointing
at `traefik-gateway`. See
[`cluster/helm/cert-manager`](../cert-manager).
