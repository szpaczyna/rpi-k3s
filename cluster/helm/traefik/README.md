# Traefik

Primary ingress controller for the cluster. Replaces `ingress-nginx`
(retired by the Kubernetes project, best-effort maintenance only until
March 2026, no releases/patches afterwards).

Routes are configured via the **Kubernetes Gateway API** (`HTTPRoute`)
rather than the legacy `Ingress` resource. A single shared `Gateway`
(`traefik-gateway`, namespace `traefik`) terminates TLS for every
hostname served by the cluster; per-application charts only need to
declare an `HTTPRoute` (or, for upstream charts that support it natively,
set `route.main.enabled` / `httpRoute.enabled` / `httproute.enabled` in
`values.yaml`).

## Topology

- **Deployment** with 2 replicas (scaled to 2-5 by HPA) and
  `topologySpreadConstraints` for HA across nodes.
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
| `web` | 80 | HTTP | Serves HTTP traffic. HTTP→HTTPS redirect is applied **per-route** via the `security-chain` middleware (see below), not at entrypoint level — this allows ACME HTTP-01 challenges to succeed on port 80. |
| `websecure` | 443 | HTTPS | `certificateRefs` lists every TLS Secret currently in use across namespaces. `mode: Terminate`. `ratelimit-global` + `fail2ban` + `hsts` + `compress` are applied entrypoint-wide; `geoblock` is per-route (see below). |

`certificateRefs` cross-namespace access requires a `ReferenceGrant` in
each target namespace — see `referencegrants.yaml` in this directory
(applied once, covers `apps`, `media`, `monitoring`, `longhorn-system`,
`auth`).

When enabling a currently-disabled app (prometheus, longhorn, nextcloud —
see their respective `values.yaml`), add its TLS secret to
`gateway.listeners.websecure.certificateRefs` here.

## Security Middlewares

### Entrypoint-level (websecure only, all routes)

Applied via `ports.websecure.http.middlewares`:

1. **`ratelimit-global`** — per-source-IP throttle (`average: 100`, `burst:
   300`), returns `429` on bursts.
2. **`fail2ban`** (`tomMoulard/fail2ban` plugin) — bans source IPs after
   repeated failures (`findtime: 10m`, `maxretry: 5`, `bantime: 1h`,
   `statuscode: 400,401,403-499`). `10.0.0.0/8` is allowlisted, which
   exempts the LAN, the MetalLB pool and the k3s pod/service CIDRs.

### Per-route (security-chain, HTTPRoutes only)

Applied via `extensionRef` on each HTTPRoute rule. The `security-chain`
Chain middleware (defined in `extraObjects`) combines:

1. **`redirect-https`** — permanent redirect from HTTP to HTTPS.
2. **`geoblock`** — Poland-only allowlist (`allowedCountries: [PL]`,
   `defaultAllow: false`). Private/LAN traffic is always allowed via
   `allowPrivate: true`; everything else gets `418`.
3. **`hsts`** — `Strict-Transport-Security` header (`stsSeconds: 31536000`,
   `stsIncludeSubdomains: true`, `stsPreload: true`).
4. **`compress`** — Brotli/gzip response compression.
   `text/event-stream` is excluded (SSE needs raw stream).

### Per-route (security-chain, HTTPRoutes only)

Applied via `extensionRef` on each HTTPRoute rule. The `security-chain`
Chain middleware (defined in `extraObjects`) combines:

1. **`redirect-https`** — permanent redirect from HTTP to HTTPS.
2. **`geoblock`** — Poland-only allowlist (`allowedCountries: [PL]`,
   `defaultAllow: false`). Private/LAN traffic is always allowed via
   `allowPrivate: true`; everything else gets `418`.

`geoblock` is per-route (not entrypoint) because cert-manager's ACME
HTTP-01 solver creates its own HTTPRoute without the security chain —
entrypoint-level geoblock would block Let's Encrypt validation servers
(non-PL IPs) and prevent certificate issuance.

The `redirect-https` middleware is also per-route for the same reason:
ACME challenges need port 80 without a redirect.

Client IPs are reliable because the Service is `externalTrafficPolicy:
Local` — real source IPs reach Traefik instead of being SNATed.

The geoblock plugin reads an IP2Location LITE DB1 database. The path
Traefik gives plugin sources (`/plugins-storage/sources/gop-*/...`)
contains a random hash, so the `geodb` initContainer downloads the `.BIN`
file from the plugin's GitHub repo into a stable path (`/data/geodb/`).
Keep the download URL in `deployment.initContainers` in sync with
`experimental.plugins.geoblock.version` when bumping the plugin.

Not affected by the chain: ACME/Let's Encrypt HTTP-01 challenges (port 80,
`web` entrypoint), the dashboard/API (`traefik` entrypoint, port 8080) and
kubelet healthchecks.

## Adding a new application with TLS

Step-by-step guide for deploying a new app with HTTPS via the shared
Gateway.

### 1. Create the application namespace (if new)

```bash
kubectl create namespace <namespace> --dry-run=client -o yaml | kubectl apply -f -
```

### 2. Add a ReferenceGrant (if new namespace)

If the app lives in a namespace not yet covered by `referencegrants.yaml`
(currently: `apps`, `media`, `monitoring`, `longhorn-system`, `auth`),
add a new entry:

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-traefik-gateway-tls-secrets
  namespace: <namespace>
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: Gateway
      namespace: traefik
  to:
    - group: ""
      kind: Secret
```

Apply it: `kubectl apply -f referencegrants.yaml`

### 3. Create a Certificate resource

Create `certificate.yaml` in the app's chart directory:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: <app>-shpaq-org-tls
  namespace: <namespace>
spec:
  dnsNames:
    - <app>.shpaq.org
  issuerRef:
    group: cert-manager.io
    kind: ClusterIssuer
    name: letsencrypt-prod
  secretName: <app>-shpaq-org-tls
  usages:
    - digital signature
    - key encipherment
```

Apply it in the deploy script: `kubectl apply -f certificate.yaml -n <namespace>`

cert-manager will automatically issue and renew the certificate. The
secret `<app>-shpaq-org-tls` will be created in the app's namespace.

### 4. Add the TLS secret to the Gateway

Add the new secret to `gateway.listeners.websecure.certificateRefs` in
`values.yaml`:

```yaml
certificateRefs:
  # ... existing entries ...
  - name: <app>-shpaq-org-tls
    namespace: <namespace>
```

### 5. Create an HTTPRoute

The HTTPRoute must reference `traefik-gateway` and include the
`security-chain` middleware via `extensionRef` on every rule. If the app
needs Authelia authentication, also create a per-namespace `authelia`
middleware (see [Authelia forwardAuth](#authelia-forwardauth)):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: <app>
  namespace: <namespace>
spec:
  parentRefs:
    - name: traefik-gateway
      namespace: traefik
      kind: Gateway
      sectionName: websecure
  hostnames:
    - "<app>.shpaq.org"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      filters:
        - type: ExtensionRef
          extensionRef:
            group: traefik.io
            kind: Middleware
            name: security-chain
        - type: ExtensionRef
          extensionRef:
            group: traefik.io
            kind: Middleware
            name: <namespace>-authelia
      backendRefs:
        - name: <service-name>
          port: <port>
```

If the app also needs an HTTPRoute for a different hostname (e.g.
`auth.shpaq.org`), repeat the same pattern with a separate HTTPRoute.

For Helm charts, add `parentRefs` and `httpRoute` to `values.yaml`:

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: traefik-gateway
      namespace: traefik
      kind: Gateway
      sectionName: websecure
```

### 6. Deploy

```bash
# Apply referencegrant (if new namespace)
kubectl apply -f referencegrants.yaml

# Deploy the app (creates Service, Deployment, HTTPRoute, Certificate)
bash deploy

# Verify
kubectl get gateway -n traefik traefik-gateway -o jsonpath='{.status.conditions[*].type}{"\n"}'
kubectl get httproute -n <namespace> <app> -o jsonpath='{.status.parents[*].conditions[*].type}{"\n"}'
kubectl get certificate -n <namespace> <app>-shpaq-org-tls
```

### Checklist

- [ ] Namespace exists
- [ ] ReferenceGrant in `referencegrants.yaml` for the namespace
- [ ] Certificate resource created (cert-manager issues the secret)
- [ ] TLS secret added to `gateway.listeners.websecure.certificateRefs`
- [ ] HTTPRoute with `security-chain` extensionRef on every rule
- [ ] HTTPRoute with `<namespace>-authelia` extensionRef (if auth needed)
- [ ] HTTPRoute `parentRefs` points to `traefik-gateway` in `traefik` namespace
- [ ] Redeploy traefik after changing `certificateRefs`
- [ ] Wait for certificate to be `Ready` before the Gateway can serve HTTPS

## Migration from ingress-nginx — annotation mapping

| nginx annotation | Gateway API / Traefik equivalent |
|---|---|
| `nginx.ingress.kubernetes.io/ssl-redirect: "true"` | Per-route, via `security-chain` middleware (contains `redirect-https`) |
| `ingressClassName: nginx` | `HTTPRoute.spec.parentRefs` → `traefik-gateway` |
| `nginx.ingress.kubernetes.io/auth-type: basic` + `auth-secret` | Traefik `Middleware` (`traefik.io/v1alpha1`) with `forwardAuth` pointing to Authelia, attached via `HTTPRoute` `filters[].extensionRef` (see [Authelia forwardAuth](#authelia-forwardauth) section) |
| `nginx.ingress.kubernetes.io/whitelist-source-range` | Traefik `Middleware` with `ipAllowList.sourceRange`, attached the same way |
| `nginx.ingress.kubernetes.io/app-root` | `HTTPRoute` rule with exact-match `/` and a `RequestRedirect` filter (`ReplaceFullPath`) |
| ExternalName Service backend | **Not supported** by Traefik's Gateway API provider (unlike its Ingress provider). Use a `ClusterIP` Service + manually managed `Endpoints` instead (see `cluster/apps/pihole`). |

### Known gaps (not ported, accepted)

- **ModSecurity / OWASP CRS (WAF)** — no built-in equivalent in Traefik
  OSS; would require a third-party plugin.

None of these affect auth, redirect, or cert-issuance behavior — only
response compression and defense-in-depth headers.

## Catch-all subdomain redirect

A wildcard HTTPRoute (`*.shpaq.org`) in `extraObjects` redirects any
unrecognized subdomain to `https://shpaq.org` (302). Gateway API
matches by hostname specificity — explicit routes (e.g. `media.shpaq.org`)
always take priority over the wildcard.

## Authelia forwardAuth

Services previously protected by `basicAuth` now use Authelia's
`forwardAuth` middleware. Each namespace that needs Authelia creates its
own middleware CRD (`<namespace>-authelia`) pointing to
`http://authelia.auth.svc.cluster.local/api/authz/forward-auth`.

The middleware is defined in each application's HTTPRoute template (not
Traefik's `extraObjects`) because Traefik's CRD provider can't resolve
middlewares across namespaces via `extensionRef`.

Pattern in HTTPRoute templates:

```yaml
# Per-namespace authelia middleware
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: authelia
  namespace: {{ .Release.Namespace }}
spec:
  forwardAuth:
    address: "http://authelia.auth.svc.cluster.local/api/authz/forward-auth"
    trustForwardHeader: true
    authResponseHeaders:
      - Remote-User
      - Remote-Groups
      - Remote-Email
---
# HTTPRoute filter reference
- type: ExtensionRef
  extensionRef:
    group: traefik.io
    kind: Middleware
    name: {{ .Release.Namespace }}-authelia
```

## Gateway API CRDs

Traefik's Helm chart no longer bundles Gateway API CRDs (removed
upstream since chart v40.2.0). They are installed separately — see
[`cluster/core/gateway-api`](../../core/gateway-api).

## cert-manager integration

Both `letsencrypt-prod` and `letsencrypt-stage` `ClusterIssuer`s use the
`http01.gatewayHTTPRoute` solver (instead of `http01.ingress`), pointing
at `traefik-gateway` in the `traefik` namespace. See
[`cluster/helm/cert-manager`](../cert-manager).

Certificate resources are created per-application (not via Gateway
annotations) because the Gateway uses `hostname: ""` on all listeners,
which prevents cert-manager from auto-determining hostnames.
