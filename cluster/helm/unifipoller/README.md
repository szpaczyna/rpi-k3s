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

The pod carries `prometheus.io/scrape: "true"`, `prometheus.io/port: "9130"` and
`prometheus.io/path: /metrics` annotations, but nothing collects them. The
`kubernetes-pods` discovery job in
[`cluster/helm/prometheus/values.yaml`](../prometheus/values.yaml) is commented
out, the active jobs are `kubernetes-apiservers`, `kubelet`, `metallb`,
`speedtest`, `raspberries`, `pihole` and `fail2ban`, and none of them mentions
unifipoller. The chart also renders no Service, so there is no address for a
static target either.

These metrics are currently unscraped. To collect them you need either the
`kubernetes-pods` job uncommented, or a Service plus a static job.

## Verifying

```sh
kubectl -n monitoring get deploy,secret unifipoller
kubectl -n monitoring logs deploy/unifipoller
```
