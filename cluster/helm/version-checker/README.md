# Version Checker

Installs [version-checker](https://github.com/jetstack/version-checker) into namespace `apps`. It exposes metrics on port 8080 and is scraped by the Prometheus instance in this repo.

## Files

| File | Description |
|---|---|
| `values-public.yaml` | Non-sensitive chart config |
| `values.enc.yaml` | Sensitive registry credentials. SOPS encrypted |
| `deploy` | Deploy script (repo, helm install, ServiceMonitor) |
| `prometheus.yaml` | Prometheus, ServiceAccount and RBAC for the bundled Prometheus |

## Deployment

    cd cluster/helm/version-checker
    ./deploy

The script:
1. Adds the `jetstack` Helm repo only if it is not configured. It does not run
   `helm repo update`.
2. Runs `helm upgrade --install version-checker` with `values-public.yaml` and
   `values.enc.yaml` (via `sops -d`)

To change the chart version, edit `VERSION` in `deploy`, run `make helm-update`
from the repository root, then run `./deploy`.

## Manual steps

Chart `0.6.2` changes the Deployment's `matchLabels` from the full label set to
`app.kubernetes.io/name` + `app.kubernetes.io/instance`. Helm cannot update an
immutable selector, so the existing Deployment must be deleted once before the
first upgrade to this version:

    kubectl -n apps delete deployment version-checker

Then run `./deploy`. The replacement Deployment is recreated by Helm. No data is
lost; version-checker is stateless.

## Secrets

`values.enc.yaml` lives next to the chart. To edit:

    sops ./values.enc.yaml

## Verification

    kubectl -n apps get deployment,svc,pod -l app.kubernetes.io/name=version-checker
    kubectl -n apps get servicemonitor version-checker

Check that:
- the Deployment is `Available`
- the Service selects the pod (endpoints non-empty)
- the ServiceMonitor exists and matches the Service labels