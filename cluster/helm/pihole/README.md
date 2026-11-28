# Pi-hole

Exposes the Pi-hole admin interface at `pihole.lan.shpaq.org` through the LAN-only
gateway. The point of this chart is name resolution only: it gives the admin
UI a hostname and a trusted certificate. It does not manage Pi-hole itself,
which runs as a service on the master node.

## How it works

Pi-hole runs on `10.0.0.2`, outside the cluster, so there is no in-cluster
workload for a Service to select. This chart therefore renders three objects:

| object | role |
|---|---|
| `Service` (`ClusterIP`, no selector) | gives `backendRefs` something to name |
| `EndpointSlice` | points that Service at `10.0.0.2:80`, written by hand |
| `HTTPRoute` | routes `pihole.lan.shpaq.org` to the Service via `traefik-internal-gateway` |

Two consequences worth knowing before editing anything here:

**The Service must stay selector-less.** Adding a `selector` produces a
Service with no endpoints, because nothing in the cluster matches it, and
`pihole.lan.shpaq.org` stops resolving with a 503 that gives no hint about the cause.

**The backend is plain HTTP on port 80, and that is intended.** Pi-hole does
serve its own HTTPS, but that certificate is `CN=pi.hole`, which does not
match `pihole.lan.shpaq.org`, so it cannot be used here. TLS terminates at Traefik
using the shared `wildcard-lan-tls` Secret, and the hop to `10.0.0.2` is
plain HTTP inside the LAN.

## Route shape

- `/` redirects (302) to `/admin/`, which is where Pi-hole's UI lives.
- Everything else is a `PathPrefix /` passthrough to the Service.

Both rules carry `security-chain-internal`, a `redirect-https`-only chain.
There is no Authelia: `*.lan.shpaq.org` is LAN-trusted.

## Configuration

| key | default | notes |
|---|---|---|
| `hostname` | `pihole.lan.shpaq.org` | covered by the Let's Encrypt `*.lan.shpaq.org` wildcard from `cluster/helm/lan-cert` |
| `upstreamIP` | `10.0.0.2` | the node Pi-hole runs on; change if it moves |
| `upstreamPort` | `80` | see the TLS note above |
| `service.port` | `80` | in-cluster Service port and route `backendRefs` port |
| `httpRoute.enabled` | `true` | |

The chart deploys into namespace `apps` (set in `deploy`), while the Gateway
it attaches to lives in namespace `traefik`.

## Adding or changing the hostname

Any `<name>.lan.shpaq.org` is covered by the `*.lan.shpaq.org` SAN in
`cluster/helm/traefik-internal/hosts.txt`, so a new name needs no new
certificate. It needs a Pi-hole CNAME to `traefik-internal.lan.shpaq.org`
instead (see below). The old `pihole.home` name redirects to the new one
during the move.

## Deploy and verify

```bash
./deploy
```

- `curl -sI https://pihole.lan.shpaq.org/` → `302` to `/admin/`
- `curl -s https://pihole.lan.shpaq.org/admin/login` → `200`, rendering the Pi-hole admin page
- `dig +short pihole.lan.shpaq.org` → `10.0.0.50`

If the hostname does not resolve at all, the problem is DNS rather than this
chart. See `provision/ansible/roles/pihole/defaults/main.yml`, which holds the
`pihole.lan.shpaq.org` CNAME. Note that `dns.hosts` entries are `A` records and take
precedence over CNAMEs there, so a stale `A` record for the same name will
shadow the CNAME silently.
