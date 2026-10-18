# Traefik (internal)

Second ingress controller, LAN only. Serves `*.home` over TLS with an `mkcert`
wildcard cert. Shares namespace `traefik` with the external instance in
[`../traefik`](../traefik), and is separated from it by its own
`GatewayClass`, not by its own namespace.

| | external | internal |
|---|---|---|
| directory | `cluster/helm/traefik-external` | `cluster/helm/traefik-internal` |
| namespace | `traefik` | `traefik` |
| release | `traefik` | `traefik-internal` |
| GatewayClass | `traefik` | `traefik-internal` |
| Gateway | `traefik-gateway` | `traefik-internal-gateway` |
| LoadBalancer IP | `10.0.0.40` | `10.0.0.50` |
| cert | Let's Encrypt, per app | one mkcert leaf for `*.home` |
| authentication | Authelia forwardAuth | none, LAN is trusted |

Chart `traefik/traefik` 42.0.0, image pinned to `v3.7.15` (kept equal to the
external instance so behaviour differences do not confound debugging), two
replicas, no HPA since LAN traffic does not burst. Dashboard and API on port
`8080` of the same LoadBalancer, unauthenticated, reachable only from the LAN:

```
http://10.0.0.50:8080/dashboard/
```

## Gateway listeners

| Listener | Port | Protocol | Notes |
|---|---|---|---|
| `web` | 80 | HTTP | Nothing routes to it yet. The `redirect-https` middleware that would send traffic to `websecure` is not wired up (see [middlewares](#middlewares)). |
| `websecure` | 443 | HTTPS | `mode: Terminate`, `certificateRefs: [wildcard-home-tls]`, `namespacePolicy: All`. |

There is no catch-all HTTPRoute, unlike the external instance. An unrecognised
`*.home` hostname gets a 404 from Traefik.

## Certificate

The whole `*.home` zone is covered by one Secret, `wildcard-home-tls` in
namespace `traefik`. It is a plain `kubernetes.io/tls` Secret applied from
SOPS-encrypted YAML, because cert-manager cannot issue from a private CA and
there is nothing public to validate against.

### The wildcard alone does not work

`.home` is a public suffix, so `media.home` is a registrable domain rather than
a subdomain. A certificate whose only SAN is `*.home` fails hostname
verification in curl and in browsers, with `no alternative certificate subject
name matches target host name`. The wildcard stays in the SAN list as a
convenience, but every hostname is also listed explicitly. Adding a hostname
means regenerating the leaf.

### Hostnames

[`hosts.txt`](hosts.txt) is the source of truth: one name per line, `#`
starts a comment. Current list:

```
home  *.home  traefik-internal.home
media.home  grafana.home  prometheus.home  longhorn.home  loki.home
```

### Regenerating the certificate

The CA in `$(mkcert -CAROOT)` is the durable part and never changes. The leaf
has to be reissued whenever a hostname is added, and it expires on its own
(about two years from each generation).

```sh
# 1. Add the hostname to hosts.txt, then:
./generate-cert

# 2. Apply the new Secret and reconcile the release:
./deploy
```

`generate-cert` reads `hosts.txt`, runs `mkcert`, wraps the result into
`wildcard-home-tls.enc.yaml` and re-encrypts it with SOPS. It prints the SAN
list and the validity window; check that the new hostname is there before
running `./deploy`.

Two hostnames are not covered by a wildcard under any circumstance: apex
`home`, and anything two levels deep such as `a.b.home`.

Verify after applying:

```sh
openssl s_client -connect 10.0.0.50:443 -servername media.home </dev/null \
  | openssl x509 -noout -ext subjectAltName
curl -sI --cacert "$(mkcert -CAROOT)/rootCA.pem" \
  --resolve media.home:443:10.0.0.50 https://media.home/
```

A `404` is the expected answer for a hostname that has no route yet. A TLS
error means the certificate was not reissued.

### Trusting the CA on clients

Clients need `rootCA.pem` from `$(mkcert -CAROOT)` installed in their trust
store. `mkcert -install` on a workstation handles it, but every other device
that opens a `*.home` URL needs it too. Android ignores user-installed CAs in
most applications, though browsers on it do accept them.

The CA is not secret. It is also not committed: export it explicitly when
distributing it.

## Shared namespace with the external instance

Both releases render into namespace `traefik`, which constrains three things.

**`extraObjects` is empty.** A second Helm release cannot take ownership of an
object name another release already owns, so this chart creates no
Middleware of its own. Routes reference the middlewares that already exist in
`traefik`, for example `redirect-https@kubernetescrd`. Uninstalling the
external release would break every `*.home` route.

**GatewayClass scoping is done with a label.** The chart creates the
`GatewayClass` but never tells the Traefik binary which one to serve, and
Traefik 3.7 has no `gatewayClass` setting; `providers.kubernetesGateway.labelSelector`
is the only filter it offers, applied to the GatewayClass object. Both
instances carry a label for this:

```yaml
gatewayClass:
  labels:
    ingress-role: internal          # external in the other chart
providers:
  kubernetesGateway:
    labelSelector: "ingress-role=internal"
```

Without it, each instance reconciles both Gateways: routes meant for one
instance get served by the other with the wrong certificate, and each one
overwrites the other's Gateway `status.addresses`. The symptom looks like two
Gateways that have swapped IP addresses.

**`instanceLabelOverride` changes object names, not only labels.** Setting it
to `traefik-internal` makes the Deployment selector, the Service selector and
`app.kubernetes.io/instance` all agree, but the chart also derives resource
names from it, so the Service is `traefik-internal` rather than
`traefik-internal-traefik`.

`topologySpreadConstraints` is scoped to
`app.kubernetes.io/instance` for the same reason: an unscoped
`DoNotSchedule` selector matches both releases' pods, since they share
`app.kubernetes.io/name: traefik`, and each instance's pods would then count
against the other's spread.

## Middlewares

No `*.home` route has middleware attached yet. Per-route middleware has to
live in the route's own namespace, because `HTTPRoute` `extensionRef` carries
`group`, `kind` and `name` but no namespace field. The cluster convention for
crossing that boundary is a `Chain` middleware, which does take a namespace:

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: security-chain-internal     # in each app namespace
spec:
  chain:
    middlewares:
      - name: redirect-https        # already in namespace traefik
        namespace: traefik
```

A plain per-namespace copy of `redirect-https` would work as well; the chain
avoids duplicating the spec. This belongs in
[`cluster/helm/middlewares`](../middlewares), which already renders
`security-chain` per namespace for the external instance.

## Deploying

```sh
./deploy
```

Applies the Secret, then reconciles the release. The Secret has to exist
before the Gateway declares a `certificateRefs` entry: a missing Secret drops
the whole `websecure` listener, not one route.

## Adding a new `*.home` application

1. Add the hostname to `hosts.txt`.
2. `./generate-cert && ./deploy`, so the certificate covers it.
3. Point the app's `HTTPRoute` at `traefik-internal-gateway` in namespace
   `traefik`, section `websecure`.
4. Add a DNS record pointing the hostname at `10.0.0.50`, in
   `provision/ansible/roles/pihole/defaults/main.yml`.
5. Give the route a `Chain` middleware in the app's own namespace if it needs
   one, per [middlewares](#middlewares).

## Verifying TLS

The gateway serves no route until an application is migrated, so TLS health is
checked against a hostname that has none. A `404` still proves the gateway
terminated TLS with a certificate the client accepted:

```sh
curl -s -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' \
  --cacert "$(mkcert -CAROOT)/rootCA.pem" \
  --resolve media.home:443:10.0.0.50 https://media.home/
# 404 0
```

`ssl_verify_result` must be `0`. Any other value means either that the
certificate is not being served or that the CA is not trusted, and the status
code alone will not tell you which.
