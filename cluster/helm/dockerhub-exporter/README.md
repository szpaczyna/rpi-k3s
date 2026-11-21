# Docker Hub Exporter

Deploys `ghcr.io/promhippie/dockerhub-exporter:2.19.4` into namespace `monitoring`.
The exporter collects repository metrics for the Docker Hub user `szpaczyn` and
serves them on port `9505` at `/metrics`.

## Scraping

The pod carries `prometheus.io/scrape`, `prometheus.io/port`, and
`prometheus.io/path` annotations. Prometheus's built-in `kubernetes-pods`
discovery rule consumes them. The copy of that job in
[`cluster/helm/prometheus/values.yaml`](../prometheus/values.yaml) stays
commented out to avoid a duplicate rule.

No Service is rendered. Annotation-based discovery scrapes the pod IP directly.

## Configuration

| Setting | Value |
|---|---|
| Image | `ghcr.io/promhippie/dockerhub-exporter:2.19.4` |
| Port | `9505` |
| Docker Hub user | `szpaczyn` |
| Security context | `runAsNonRoot: true`, `runAsUser: 1337`, RuntimeDefault seccomp, read-only root filesystem |
| Requests / limits | CPU `10m` / `100m`, memory `32Mi` / `128Mi` |
| Node selector | `kubernetes.io/role: worker` |

Change `env.DOCKERHUB_EXPORTER_USER` in `values.yaml` to scrape a different
namespace. Add `DOCKERHUB_EXPORTER_ORG` instead when the namespace is an
organization.

## Grafana dashboard

Import [`dashboards/dockerhub-exporter.json`](dashboards/dockerhub-exporter.json)
through **Dashboards > New > Import**. Select the Prometheus datasource when
Grafana asks for `DS_PROMETHEUS`.

The dashboard shows cumulative pulls, pulls added in the selected time range,
and a repository table with pulls, status, and last update time. The status
column maps Docker Hub values `1` to Active and `6` to Archived. It uses a
single `Repository` variable populated from `dockerhub_repo_pulls`. The layout
follows Grafana dashboard
[24696](https://grafana.com/grafana/dashboards/24696-docker-hub-image-pulls/).

Grafana's dashboard sidecar is not enabled in this repository, so the JSON is
for manual import.

## Deploying

```sh
cd cluster/helm/dockerhub-exporter
./deploy
```

Extra arguments are passed through to `helm upgrade --install`.

## Verifying

```sh
kubectl -n monitoring get pod -l app.kubernetes.io/name=dockerhub-exporter -o wide
kubectl -n monitoring logs deploy/dockerhub-exporter
```
