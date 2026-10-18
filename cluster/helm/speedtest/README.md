# Speedtest

Prometheus exporter that runs internet speed tests from `rpi-k3s-worker-01` and
serves the results on port `9469`. Deployed into namespace `monitoring` by
[`deploy`](deploy).

## Why the pod is pinned to one node

The pod uses `nodeSelector: kubernetes.io/hostname: rpi-k3s-worker-01`
(`10.0.0.12`). Most charts in this repository select on `kubernetes.io/role: worker`
instead. This one does not: the exporter measures the connectivity of the node it
runs on, so the node is part of the measurement.

If `rpi-k3s-worker-01` is down, the pod stays `Pending`. It does not move to
another node.

## Why `hostNetwork` and `hostPID`

| Setting | Effect |
|---|---|
| `hostNetwork: true` | The pod shares the node's network namespace. The exporter listens on the node address, `10.0.0.12:9469`, and its traffic leaves through the node's own network stack. No other `hostNetwork` pod can bind port `9469` on that node. |
| `hostPID: true` | Asserted by the chart comment as a requirement for measuring the node's connectivity. The repository records no mechanism, so treat it as load-bearing until you know otherwise. |

## Scraping

Prometheus reaches this exporter through a static target, not through pod
annotations. The pod still carries `prometheus.io/scrape` and `prometheus.io/port`
annotations, but the `kubernetes-pods` discovery job in
[`cluster/helm/prometheus/values.yaml`](../prometheus/values.yaml) is commented out.
The `speedtest` job there scrapes `10.0.0.12:9469` on path `/probe` at a 29 minute
interval, with a 90 second timeout.

If the node changes, update both the `nodeSelector` here and the static target in
the Prometheus values.

## Configuration

| Setting | Value |
|---|---|
| Image | `szpaczyn/prometheus-speedtest-exporter:v1.1.0` |
| Port | `9469` |
| Security context | `runAsNonRoot: true`, `runAsUser: 65535` |
| Requests / limits | CPU `10m` / `100m`, memory `24Mi` / `128Mi` |
| Affinity | Requires `kubernetes.io/os=linux` |
| Tolerations | Any `NoSchedule` taint (`operator: Exists`) |

There is no Service. The deployment name is `speedtest`.

## Deploying

```sh
cd cluster/helm/speedtest
./deploy
```

Extra arguments are passed through to `helm upgrade --install`.

The chart was converted from a plain manifest. Helm cannot adopt a Deployment it
did not create, so delete the old one before the first Helm install:

```sh
kubectl delete deployment speedtest -n monitoring
```

## Verifying

```sh
kubectl -n monitoring get pod -l app.kubernetes.io/name=speedtest -o wide
```

The `NODE` column should read `rpi-k3s-worker-01`.
