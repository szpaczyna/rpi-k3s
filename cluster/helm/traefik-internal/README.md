# Traefik (internal)

Second ingress controller, LAN only. Serves `*.lan.shpaq.org` over TLS with
the Let's Encrypt wildcard from [`../lan-cert`](../lan-cert), and redirects the
old `*.home` names there, which keep an `mkcert` leaf until the cleanup. Shares
namespace `traefik` with the external instance in [`../traefik`](../traefik),
and is separated from it by its own `GatewayClass`, not by its own namespace.

| | external | internal |
|---|---|---|
| directory | `cluster/helm/traefik-external` | `cluster/helm/traefik-internal` |
| namespace | `traefik` | `traefik` |
| release | `traefik` | `traefik-internal` |
| GatewayClass | `traefik` | `traefik-internal` |
| Gateway | `traefik-gateway` | `traefik-internal-gateway` |
| LoadBalancer IP | `10.0.0.40` | `10.0.0.50` |
| cert | Let's Encrypt, per app | Let's Encrypt `*.lan.shpaq.org`, mkcert leaf for `*.home` |
| authentication | Authelia forwardAuth | Authelia forwardAuth on the web UIs |

Chart `traefik/traefik` at the `VERSION` pinned in `deploy`, image pinned to
`v3.7.15` (kept equal to the external instance so behaviour differences do
not confound debugging), two
replicas, no HPA since LAN traffic does not burst. The dashboard is served by
the chart's dashboard IngressRoute on `websecure`, behind the `authelia`
Middleware, with the `wildcard-home-tls` certificate:

```
https://traefik-internal.lan.shpaq.org/dashboard/
```

Port `8080` is no longer on the LoadBalancer. The ClusterIP Service
`traefik-internal-dashboard` carries it for the homepage widget. The
IngressRoute sets the `kubernetes.io/ingress.class: traefik-internal`
annotation because the chart only writes `ingressClassName` when
`ingressClass.enabled` is true, and the CRD provider skips unclassed objects.

## Gateway listeners

| Listener | Port | Protocol | Notes |
|---|---|---|---|
| `web` | 80 | HTTP | Only the `*.home` redirect routes to it. `redirect-https` is attached to `websecure` routes rather than to this listener, so no other request needs it (see [middlewares](#middlewares)). |
| `websecure` | 443 | HTTPS | `mode: Terminate`, `certificateRefs: [wildcard-home-tls, wildcard-lan-tls]`, `namespacePolicy: All`. |

There is no catch-all HTTPRoute for `lan.shpaq.org`, unlike the external
instance. An unrecognised `*.lan.shpaq.org` hostname gets a 404 from Traefik.

## Redirect from `*.home`

`extraObjects` renders an HTTPRoute and a Middleware, both named
`redirect-home-to-lan`, that answer every `<label>.home` request on either
listener with a 301 to `https://<label>.lan.shpaq.org`, keeping the port, path
and query. The Gateway API `RequestRedirect` filter only sets a fixed hostname,
so the route uses a Traefik `redirectRegex` Middleware instead. Pi-hole keeps a
CNAME from the `.home` name of each LAN web app to its new name, so old
bookmarks still resolve; device names under `.home` are gone.

```sh
curl -sI https://media.home/radarr/ | grep -i '^location'
# location: https://media.lan.shpaq.org/radarr/
```

The redirect, the `.home` SANs and the remaining `.home` CNAMEs stay for old
bookmarks; remove them together.

## Certificates

The `websecure` listener references two `kubernetes.io/tls` Secrets in
namespace `traefik`. Their SANs do not overlap, so Traefik picks one by SNI.

| Secret | SANs | issuer | managed by |
|---|---|---|---|
| `wildcard-lan-tls` | `*.lan.shpaq.org` | Let's Encrypt | [`../lan-cert`](../lan-cert), weekly renewal CronJob |
| `wildcard-home-tls` | `home`, `*.home`, each `.home` name | mkcert CA | [`hosts.txt`](hosts.txt) and `./generate-cert`, SOPS-encrypted here |

`wildcard-lan-tls` comes from a public CA, so devices need no mkcert CA for
`*.lan.shpaq.org`, and a new `lan.shpaq.org` application needs no new
certificate. `deploy` stops if the Secret is missing; run
[`../lan-cert/deploy`](../lan-cert) first on a fresh cluster.

`wildcard-home-tls` exists only for the `.home` redirect and goes away with
it. `deploy` applies it from SOPS-encrypted YAML because cert-manager cannot
issue from a private CA.

### The `.home` wildcard alone does not work

`.home` is a public suffix, so `media.home` is a registrable domain rather than
a subdomain. A certificate whose only SAN is `*.home` fails hostname
verification in curl and in browsers, with `no alternative certificate subject
name matches target host name`. The `.home` wildcard stays in the SAN list as a
convenience, but every `.home` hostname is also listed explicitly.

### Hostnames

[`hosts.txt`](hosts.txt) is the source of truth: one name per line, `#`
starts a comment. Current list:

```
home  *.home  traefik-internal.home
media.home  grafana.home  prometheus.home  longhorn.home  loki.home
pihole.home  homepage.home
```

### Regenerating the certificate

The CA in `$(mkcert -CAROOT)` is the durable part and never changes. The leaf
has to be reissued whenever `hosts.txt` changes, and it expires on its own
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

A wildcard never covers the apex (`lan.shpaq.org`, `home`) or anything two
levels deep such as `a.b.lan.shpaq.org`. Neither certificate covers
`lan.shpaq.org` itself.

Check the SANs after applying:

```sh
openssl s_client -connect 10.0.0.50:443 -servername media.home </dev/null \
  | openssl x509 -noout -ext subjectAltName
```

The full TLS check is under [Verifying TLS](#verifying-tls).

### Trusting the CA on clients

Only clients that still open `*.home` URLs need `rootCA.pem` from
`$(mkcert -CAROOT)` in their trust store; `*.lan.shpaq.org` needs no extra CA.
`mkcert -install` on a workstation handles it. Android ignores user-installed
CAs in most applications, though browsers on it do accept them.

The CA is not secret. It is also not committed: export it explicitly when
distributing it.

## Shared namespace with the external instance

Both releases render into namespace `traefik`, which constrains three things.

**`extraObjects` holds only the `.home` redirect.** A second Helm release
cannot take ownership of an object name another release already owns, so this
chart re-creates none of the shared middlewares, and its own objects use names
the external release does not. Routes reference the middlewares that already
exist in `traefik`, for example `redirect-https@kubernetescrd`. Uninstalling
the external release would break every `*.lan.shpaq.org` route.

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

The `*.lan.shpaq.org` routes for media, loki, pihole, grafana and prometheus
attach `security-chain-internal`. `longhorn.lan.shpaq.org` has none: the upstream Longhorn
chart's `httproute.yaml` has no `filters` hook, so the route cannot take one.

Per-route middleware has to live in the route's own namespace, because
`HTTPRoute` `extensionRef` carries `group`, `kind` and `name` but no namespace
field. The convention for crossing that boundary is a `Chain` middleware, which
does take a namespace:

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
avoids duplicating the spec. [`cluster/helm/middlewares`](../middlewares)
renders `security-chain-internal` for each namespace listed in its values,
next to `security-chain` for the external instance.

## Deploying

```sh
./deploy
```

Applies `wildcard-home-tls`, checks that `wildcard-lan-tls` exists, then
reconciles the release. Both Secrets have to exist before the Gateway declares
them in `certificateRefs`: a missing Secret drops the whole `websecure`
listener, not one route.

## Adding a new `*.lan.shpaq.org` application

1. Point the app's `HTTPRoute` at `traefik-internal-gateway` in namespace
   `traefik`, section `websecure`.
2. Add a CNAME from the hostname to `traefik-internal.lan.shpaq.org`, in
   `provision/ansible/roles/pihole/defaults/main.yml`.
3. Give the route a `Chain` middleware in the app's own namespace if it needs
   one, per [middlewares](#middlewares).

## Verifying TLS

The status code is whatever the route answers; only `ssl_verify_result`
matters here, and it must be `0`. `*.lan.shpaq.org` verifies against the
system trust store, `*.home` against the mkcert CA:

```sh
curl -s -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' \
  --resolve media.lan.shpaq.org:443:10.0.0.50 https://media.lan.shpaq.org/
# 200 0

curl -s -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' \
  --cacert "$(mkcert -CAROOT)/rootCA.pem" \
  --resolve media.home:443:10.0.0.50 https://media.home/
# 301 0
```

Any other `ssl_verify_result` means either that the
certificate is not being served or that the CA is not trusted, and the status
code alone will not tell you which.
