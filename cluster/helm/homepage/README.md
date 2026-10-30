# Homepage

[Homepage](https://github.com/gethomepage/homepage) dashboard at
`https://homepage.home`, attached to `traefik-internal-gateway` with
`security-chain-internal`. LAN only, no login: anyone on the LAN sees the
widget data, so the credentials below should be read-only accounts.

Deployed into namespace `media` by [`deploy`](deploy), so the *arr widgets can
read their API keys straight from the `media-exporter` Secret.

## Configuration

Every file under `/app/config` comes from the `config` map in
`values-public.yaml`, one ConfigMap key per file. A pod checksum annotation
restarts the pod when the map changes, because `subPath` mounts do not follow
ConfigMap updates.

Discovery from Ingress, IngressRoute and HTTPRoute annotations is off
(`kubernetes.yaml`), so the ClusterRole only grants `get`/`list` on
namespaces, pods and pod metrics. Those feed the CPU/memory line on each
service card (`namespace` + `app`, matched against `app.kubernetes.io/name`,
or `podSelector`).

The `Servers` group shows one `customapi` card per host, plus the `rpi-k3s`
cluster total. Each card runs one Prometheus query built from node_exporter
metrics (`job="raspberries"` for the standalone Pis, the
`prometheus-node-exporter` service for the k3s nodes). Missing metrics show
as `-`.

Widget `url`s use in-cluster Service names. `href`s are what the browser
opens, so they stay on `*.home`; Gitea and Booklore have no `*.home` route and
link to `*.shpaq.org`.

## Credentials

Config files reference `{{HOMEPAGE_VAR_*}}` placeholders, which homepage
fills from the environment.

| Variable | Source |
|---|---|
| `HOMEPAGE_VAR_GITEA_TOKEN` | `values.enc.yaml` |
| `HOMEPAGE_VAR_PIHOLE_KEY` | `values.enc.yaml` (Pi-hole v6 app password) |
| `HOMEPAGE_VAR_KODI_USERNAME`, `_PASSWORD` | `values.enc.yaml` (Kodi web server on greypi) |
| `HOMEPAGE_VAR_UNIFI_USERNAME`, `_PASSWORD` | `deploy`, from `upConfig` in `../unifipoller/values.enc.yaml` |
| `HOMEPAGE_VAR_{SONARR,RADARR,LIDARR,READARR,PROWLARR,BAZARR}_KEY` | `media-exporter` Secret, `optional: true` |

`values.enc.yaml` holds an `env` map that the chart renders into the
`homepage-env` Secret:

```sh
sops ./values.enc.yaml
```

After rotating *arr keys with `../media-stack/sync-exportarr-keys.sh`, run
`kubectl -n media rollout restart deploy/homepage`: environment variables from
a Secret are read once, at container start.

## Deploy and verify

```sh
./deploy        # needs sops, yq v4 (TOML support) and the repo's PGP key
```

- `kubectl -n media rollout status deploy/homepage`
- `curl -sI https://homepage.home/` returns `200`
- `kubectl -n media logs deploy/homepage` has no `Host validation failed` or widget errors

`homepage.home` must be in `../traefik-internal/hosts.txt` (certificate SAN)
and in the Pi-hole CNAME list in
`provision/ansible/roles/pihole/defaults/main.yml`.
