# Middlewares

Renders the Traefik `Middleware` objects that application HTTPRoutes reference by
name. The release installs into namespace `middlewares`, but that namespace holds
no objects. Each Middleware is created in the application namespace listed in
[`values.yaml`](values.yaml).

The chains reference four shared middlewares in namespace `traefik`: `redirect-https`,
`geoblock`, `hsts` and `compress`. Those are defined in the `extraObjects` of
[`traefik-external`](../traefik-external/values.yaml), not in this chart.

## What it creates

| Middleware | Created in | Contents |
|---|---|---|
| `security-chain` | `externalChainNamespaces`: `apps`, `media` | `redirect-https`, `geoblock`, `hsts`, `compress` |
| `security-chain-nogeo` | `externalChainNamespaces` | `redirect-https`, `hsts`, `compress` |
| `security-chain-internal` | `namespaces`: `apps`, `logging`, `media`, `monitoring` | `redirect-https` |
| `authelia` | `autheliaNamespaces`: `apps` | `forwardAuth` to `http://authelia.auth.svc.cluster.local/api/authz/forward-auth`, passing `Remote-User`, `Remote-Groups`, `Remote-Email` |

The `security-chain` variants on WAN routes use `geoblock`, a plugin that only
`traefik-external` loads. The internal gateway has no `geoblock` and does not use
`security-chain` at all.

## Why the chains are copied per namespace

An HTTPRoute `extensionRef` names a Middleware without a namespace field. The
Middleware therefore has to exist in the route's own namespace. This chart creates
a copy of each chain in each namespace that needs one. Each chain member sets
`namespace: traefik`, so the shared definitions are reused and not duplicated.

## Changing the lists

The lists in `values.yaml` control which objects exist. Helm deletes a Middleware
when its namespace leaves the list.

- **Removing a namespace from `autheliaNamespaces`** breaks routes that still
  reference `authelia`. Traefik falls through to the catch-all redirect instead of
  serving the app. Remove the namespace only after its routes stop using the
  middleware.
- **`externalChainNamespaces`** should hold only namespaces that still have a
  `*.shpaq.org` route. Remove a namespace when its last WAN route is gone.
- **`namespaces`** must include each namespace with a `*.home` route. Routes on the
  internal gateway reference `security-chain-internal`.

Examples of current consumers: `shpaq-org` uses `security-chain-nogeo`, `whoops`,
`gitea` and `bitwarden` use `security-chain`, and `pihole` and `grafana` use
`security-chain-internal`.

## Deploying

```sh
cd cluster/helm/middlewares
./deploy
```

Add a namespace to the relevant list before deploying a chart whose routes need
the middleware in that namespace. The [Authelia README](../authelia/README.md)
explains the same ordering for `authelia`.

## Related

- [traefik-external](../traefik-external): defines the shared `redirect-https`, `geoblock`, `hsts` and `compress` middlewares.
- [traefik-internal](../traefik-internal): the `*.home` gateway and the reasoning behind `security-chain-internal`.
- [Repository README](../../../README.md)
