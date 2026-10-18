# Default backend

Catch-all for requests that no hostname-specific route claims: bare LoadBalancer
IP access and unknown hosts. It plays the role of ingress-nginx's `defaultBackend`
for the Traefik Gateway API setup.

Deployed by [`deploy`](deploy) into namespace `traefik`. The Deployment, Service
and HTTPRoute are all named `defaultbackend`.

## What it runs

| Object | Detail |
|---|---|
| Image | `szpaczyn/defaultbackend-arm64:v0.1.0` (`IfNotPresent`) |
| Deployment | 1 replica, `nodeSelector: kubernetes.io/role: worker` |
| Service | ClusterIP, port `80` to container port `8080` |
| HTTPRoute | Parent `traefik-gateway` in `traefik`, sections `web` and `websecure`, path prefix `/` |
| Resources | requests `10m` / `16Mi`, limits `100m` / `32Mi` |

The values file describes the image as nginx-unprivileged: it listens on `8080` as
uid/gid `101`. The root filesystem is read-only, and `/var/cache/nginx` and `/tmp`
are `emptyDir` volumes.

## Why there is no hostname and no security chain

The HTTPRoute declares no `hostnames` and no filters. Without hostnames it matches
every host, so it answers whatever no other route claims. Routes that declare a
hostname take precedence over it.

It attaches no `security-chain` middleware, on purpose. An unclaimed host has no
identity to authenticate, so sending it to the chain would bounce it to the
Authelia portal on `auth.shpaq.org` instead of answering it.

## Precedence with `*.shpaq.org`

`traefik-external` declares its own hostname route, `catch-all-subdomains`, for
`*.shpaq.org`, attached to the `websecure` listener only. It answers with a 302 to
`https://shpaq.org`. So on HTTPS an unknown name under `shpaq.org` gets that
redirect, and bare-IP requests and names outside `shpaq.org` reach this backend.
Plain HTTP is different: `catch-all-subdomains` is not attached to `web`, so an
unknown `*.shpaq.org` on port 80 lands here.

## Verifying

Expected status for an unclaimed host on the external IP:

```sh
curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: unknown.example' http://10.0.0.40/
```

The image serves `200`, not `404`. Its `nginx` config is a plain static site:
`location /` points at `/usr/share/nginx/html`, and `error_page 404` is commented
out. `index.html` in the image is a copy of the shpaq.org landing page, so an
unclaimed host currently gets that page with a `200` status. Only a path that
matches no file returns nginx's built-in `404`.

The probes send `GET /` (`templates/deployment.yaml`), and Kubernetes treats
`200`-`399` as healthy, so this arrangement is self-consistent. The `404` wording
in the `values.yaml` header comment does not match what the image actually does.

## Deploying

```sh
cd cluster/helm/defaultbackend
./deploy
```

The script takes no arguments and runs `helm upgrade --install` with the chart's
`values.yaml`.

## Related

- [traefik-external](../traefik-external): owns `traefik-gateway` and the `catch-all-subdomains` route.
- [traefik-internal](../traefik-internal): the LAN gateway. This backend is not attached to it.
- [Repository README](../../../README.md)
