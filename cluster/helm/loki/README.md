# Loki & Fluent Bit

Cluster-wide log aggregation for `rpi-k3s`:

- **Loki** (`grafana/loki`, SingleBinary) — receives all logs, stores them on
  Longhorn (`filesystem` storage type, single replica).
- **Fluent Bit** (`fluent/fluent-bit`, DaemonSet — one pod per node) — tails
  every container's stdout/stderr and ships it to `loki-headless:3100`,
  merging the container JSON into the record and attaching Kubernetes
  metadata as Loki labels (`namespace`, `pod`, `container`, `host`, ...).

Deployment: `./deploy` (installs Loki first, then Fluent Bit).

## GeoIP enrichment of Traefik access logs

Traefik's access logs (JSON, one line per request) already contain the real
client address in `ClientHost` (see `cluster/helm/traefik-external` —
`service.externalTrafficPolicy: Local`). Fluent Bit enriches those records
with the client's geolocation from the MaxMind **GeoLite2** database, so each
access-log line gains `country_name`, `country_code` (plus `city_name`,
`latitude`, `longitude` for Grafana geo maps).

### Data flow

```text
client ─▶ Traefik (access log JSON, ClientHost = real IP)
        ─▶ Fluent Bit ─▶ geoip2 filter (Match_Regex kube\.var\.log\.containers\.traefik-.*)
        ─▶ + country_code / country_name / city_name / latitude / longitude
        ─▶ Loki ─▶ Grafana
```

The `geoip2` filter only touches records from `traefik-*` pods — all other
cluster logs skip the lookup entirely. `Log_Level error` silences warnings
for records without a `ClientHost` and for private/LAN IPs.

### Files

| File | Role |
|---|---|
| `fluentbit-values.yaml` | `geoip2` filter, read-only mount of the shared DB volume |
| `maxmind-geoip.enc.yaml` | SOPS-encrypted MaxMind credentials (`account_id`, `license_key`) |
| `geolite2-cronjob.yaml` | Static PV/PVC on NFS (`/data/nfs/geolite2`, like media-stack) + `geolite2-updater` CronJob refreshing the DB every two weeks and rolling the DaemonSet so pods reload it |

The GeoLite2 **City** database is used (country + city + coordinates). The
official `ghcr.io/maxmind/geoipupdate` client (pinned to `v8.0.0`) downloads
it; the free GeoLite2 tier is enough. The CronJob restarts the fluent-bit
DaemonSet with an `alpine/kubectl` image (pinned to `1.36.4`) so the running
pods re-open the updated `.mmdb`.

### Images

The CronJob uses pinned images (no `latest`, no floating tags):

| Container | Image |
|---|---|
| `update-geolite2` | `ghcr.io/maxmind/geoipupdate:v8.0.0` |
| `restart-fluentbit` | `alpine/kubectl:1.36.4` |

### Prerequisites

A free MaxMind account (for the license key): <https://www.maxmind.com/en/geolite2/signup>

### Setup (first time)

```bash
# 1. Fill in account_id / license_key in maxmind-geoip.enc.yaml, then:
sops -e -i maxmind-geoip.enc.yaml
kubectl apply -f maxmind-geoip.enc.yaml

# 2. PVC + CronJob (must exist before the fluent-bit chart upgrade)
kubectl apply -f geolite2-cronjob.yaml

# 3. Deploy the charts (rolls fluent-bit DaemonSet with the new filter)
./deploy
```

Fluent bit pods never download the database — they just read the shared
volume. It is refreshed by the CronJob every two weeks, which also runs
`kubectl rollout restart daemonset/fluent-bit` so the running pods re-open the
updated `.mmdb`.

On a fresh/empty volume (e.g. first deploy on a new PVC) bootstrap it with a
one-off run before the fluent-bit chart rolls out:

```bash
kubectl create job --from=cronjob/geolite2-updater geolite2-bootstrap -n logging
```

The database lives on the NFS share exported by `rpi-k3s-worker-00`:
`/data/nfs/geolite2` (the same pattern as media-stack's `/data/media` — a
static `hostPath` PV/PVC pair on the `local-path` storage class, pinned with
`volumeName`). `worker-00` serves it locally, every other node reaches it over
NFS, so all fluent-bit pods read the same file. The target directory must
exist on `worker-00` (NFS server) before the PV is used:

### Querying in Grafana

Traefik access logs with a resolvable country:

```logql
{job="fluentbit", namespace="kube-system", container="traefik"} | json | country_code != ""
```

Requests by country (bar / map):

```logql
sum by (country_code) (count_over_time({job="fluentbit", namespace="kube-system", container="traefik"} | json | country_code != "" [5m]))
```

#### Geomap (world map of request origins)

Visualization: **Geomap**, layer type **Markers**, Location data:
**Lookup** (field `Field`) — this maps the ISO `country_code` to the country
center via Grafana's built-in country lookup, so it works with aggregated
(counted) data. The panel in `traefik-loki-dashboard.json` ("World Traffic")
uses a metric query + `Reduce` (sum) transformation:

```logql
sum by (country_code) (count_over_time({job="fluentbit", namespace="kube-system", container="traefik"} | json | country_code != "" | __error__="" [5m]))
```

The `Reduce` transform turns the `country_code` label into the `Field` column
and the request count into `Total` (used for marker size/color).

#### Geoblock logs (blocked requests by country)

The geoblock plugin emits error-level messages (not access logs), so the
`geoip2` filter cannot enrich them — there is no `ClientHost` field. A
dedicated Fluent Bit `parser` filter regex-matches the country code from
the `blocked request from XX` text and sets `blocked_country` as a structured
field in the log body.

Geoblock logs from a specific country:

```logql
{job="fluentbit", container="traefik"} | json | blocked_country = "SG"
```

All blocked requests:

```logql
{job="fluentbit", container="traefik"} | json | blocked_country != ""
```

Blocked requests by country (last 24h):

```logql
sum by (blocked_country) (count_over_time({job="fluentbit", container="traefik"} | json | blocked_country != "" [24h]))
```

### Dashboard panels & queries

`cluster/helm/traefik-external/traefik-loki-dashboard.json` ("Traefik Via Loki") ships
with the following additional panels:

| Panel | Query (metric) |
|---|---|
| Unique user visits | `count by () (sum by (ClientHost) (count_over_time({job="fluentbit", namespace="kube-system", container="traefik"} \| json \| ClientHost != "" \| ClientHost !~ "10.42.*" \| __error__="" [$__interval])))` |
| Top IPs | `topk(10, sum by (ClientHost) (count_over_time(... \| ClientHost != "" \| ClientHost !~ "10.42.*" ...)))` |
| Top Requested Pages | `topk(10, sum by (RequestPath) (count_over_time(... \| RequestPath != "" \| RequestPath != "/" ...)))` |
| Top User Agents | `topk(10, sum by (request_user_agent) (count_over_time(... \| json \| regexp "\"request_User-Agent\":\"(?P<request_user_agent>[^\"]*)\"" ...)))` |
| Top Bots | same as Top User Agents with `request_user_agent =~ "(?i)(bot\|crawler\|spider\|headless\|scan\|curl\|python)"` |
| Top HTTP Referers | `topk(10, sum by (request_referer) (count_over_time(... \| json \| regexp "\"request_Referer\":\"(?P<request_referer>[^\"]*)\"" ...)))` |

The **Top User Agents**, **Top Bots** and **Top HTTP Referers** panels need the
`User-Agent` / `Referer` request headers in the Traefik access log. Enable them
in `cluster/helm/traefik-external/values.yaml` under `accessLog.fields.headers`:

```yaml
accessLog:
  fields:
    headers:
      defaultMode: drop
      names:
        User-Agent: keep
        Referer: keep
```

Traefik v3 logs them as `request_User-Agent` / `request_Referer` keys; the
`regexp` stage above renames them to `request_user_agent` / `request_referer`
(after the `| json` stage), because label names with `-` are awkward in LogQL.
After redeploying Traefik the panels start populating (older logs won't have
the headers).

**Note:** the `latitude`/`longitude` fields added by the geoip2 filter are
still available for **Coordinates**-based maps if you need per-request
markers, but keep such panels short-ranged (last 15m/1h) — one point per log
line. The "World Traffic" panel uses the aggregated lookup approach instead.

### Notes & caveats

- **Private / LAN IPs** (e.g. `10.0.0.0/8` LAN clients, health checks) have
  no entry in GeoLite2 → no country fields. Only internet-facing traffic gets
  a country.
- The `geoip2` filter loads the database at startup; that's why the CronJob
  restarts the DaemonSet after each update.
- The fluent-bit pods mount the volume read-only; only the CronJob writes.
- GeoLite2 data by MaxMind, licensed CC BY-SA 4.0 — keep the attribution if
  this data is redistributed.

## Ingress

Loki's query API is reachable at `loki.home`, on the LAN only, via
`traefik-internal-gateway`. See
[`cluster/helm/traefik-internal`](../traefik-internal).

### `GET /` returns 404, and that is correct

Loki serves no route at the root. A 404 on `https://loki.home/` means the
route is working. Useful probes:

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://loki.home/ready        # 200
curl -s https://loki.home/loki/api/v1/labels | head                    # 200, JSON
```

### Why the HTTPRoute is hand-written

The Loki chart has no Gateway API support, unlike the Grafana and Prometheus
charts, which expose `route.main` / `server.route.main` toggles. The
`HTTPRoute` in `loki-values.yaml` is therefore a `extraObjects` entry rather
than a values-driven toggle. Do not try to move it into a native values block;
the chart has nowhere to put it and it will be silently dropped.

### GeoIP enrichment covers both gateways

`fluentbit-values.yaml` matches `traefik-.*` pods, which covers
`traefik-external-*` and `traefik-internal-*` alike, so both instances are
collected. `*.home` requests are only present in the `traefik-internal` pod's
logs, since the external gateway serves only `*.shpaq.org`.

## Host logs (auth.log, fail2ban.log)

Only blueberry (the `pihole` group) ships host logs. A host Fluent Bit agent,
installed by the `log_shipper` Ansible role in `provision/ansible/`, pushes
`/var/log/auth.log` and `/var/log/fail2ban.log` to
`https://loki.home/loki/api/v1/push` (push-only HTTPRoute,
`PathPrefix /loki/api/v1/push`). The cluster Fluent Bit DaemonSet collects
container logs only.

Labels are deliberately limited to `job`, `host`, `log_file` to keep stream
cardinality low. `src_ip` (and `user`, `action` for fail2ban) are extracted
at ingest time by a Fluent Bit lua filter and stored as fields in the JSON
body, so they survive `count_over_time` aggregations via `| json`:

```logql
{job="host"} | json | src_ip != ""
```

Top offending IPs:

```logql
topk(10, sum by (src_ip) (count_over_time({job="host",log_file="auth.log"} | json | src_ip != "" [1h])))
```
