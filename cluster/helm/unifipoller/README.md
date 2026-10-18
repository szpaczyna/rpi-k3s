# UniFi Poller (unifipoller)

Chart for [UnPoller](https://unpoller.com/), which polls the UniFi controller and
serves its metrics on port `9130`. Deployed into namespace `monitoring` by
[`deploy`](deploy). The chart metadata points to the upstream
[unpoller helm-chart](https://github.com/unpoller/helm-chart).

## Two values files

| File | Committed as | Holds |
|---|---|---|
| `values-public.yaml` | Plain YAML | Image, security context, probes, resources, scheduling, Prometheus annotations |
| `values.enc.yaml` | SOPS-encrypted | `upConfig`, the UnPoller configuration that the chart writes to `up.conf` |

Non-sensitive settings stay readable in Git. The UnPoller configuration stays
encrypted. `deploy` passes both files to `helm upgrade --install` with `--values`.
The only source of `upConfig` is `values.enc.yaml`, because `values-public.yaml`
does not set it.

## Deploying

```sh
cd cluster/helm/unifipoller
./deploy
```

The script needs `sops` and access to the key that decrypts `values.enc.yaml`.
To edit the encrypted file:

```sh
sops ./values.enc.yaml
```

## What runs

- **Deployment** `unifipoller`, 1 replica, `nodeSelector: kubernetes.io/role: worker`.
- **Image** `ghcr.io/unpoller/unpoller:v3.5.0`. The image tag in `values-public.yaml`
  sets the running version. `appVersion` in `Chart.yaml` is only a label.
- **Secret** `unifipoller` holds `up.conf`, mounted at `/etc/unpoller/up.conf`.
- **Security context** runs as uid `1000` with `fsGroup: 2000`. The root filesystem
  is read-only and all capabilities are dropped. The ServiceAccount does not mount
  an API token.
- **Ports** `9130` on both TCP and UDP. Probes are HTTP `GET /` on the `tcp` port.
- **Resources** requests and limits are both `100m` CPU and `128Mi` memory.
- **No Service.** The chart does not create one.

## Changing the configuration

The Deployment has no checksum annotation and the config is mounted with `subPath`,
so a new Secret does not restart the pod or update the mounted file. After
`./deploy`, restart the pod:

```sh
kubectl -n monitoring rollout restart deploy/unifipoller
```

## Metrics scraping

The pod is scraped by the `kubernetes-pods` job on port `9130` at `/metrics`,
discovered through its `prometheus.io/scrape`, `prometheus.io/port` and
`prometheus.io/path` annotations.

That job is not written in this repository. It comes from the default config of
the upstream [`prometheus-community/prometheus`](../prometheus) chart, which
`../prometheus/deploy` installs at `29.37.0` with this repo's values as an
override. The chart concatenates its own default scrape config with
`serverFiles` and `extraScrapeConfigs`, so the rendered `prometheus.yml` holds
three groups: the upstream defaults (`kubernetes-api-servers`, `kubernetes-nodes`,
`kubernetes-nodes-cadvisor`, `kubernetes-pods`, `kubernetes-pods-slow`,
`kubernetes-service-endpoints`, `kubernetes-services`, `prometheus`,
`prometheus-pushgateway`), the jobs in this repo's `serverFiles`
(`kubernetes-apiservers`, `kubelet`), and the static targets in
`extraScrapeConfigs` (`metallb`, `speedtest`, `raspberries`, `pihole`,
`fail2ban`).

The commented-out `kubernetes-pods` job further down
[`../prometheus/values.yaml`](../prometheus/values.yaml) is a leftover copy of
what upstream already provides. Leave it commented, or you get a duplicate
job.

Note that `PodMonitor` and `ServiceMonitor` objects are not honoured here.
There is no prometheus-operator in this cluster and the CRDs are not installed,
so any such object rendered by another chart is inert.

## Verifying

```sh
kubectl -n monitoring get deploy,secret unifipoller
kubectl -n monitoring logs deploy/unifipoller
```
