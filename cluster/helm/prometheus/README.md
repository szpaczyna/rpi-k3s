# Prometheus

Metrics collection for the cluster, deployed with the upstream chart
`prometheus-community/prometheus` (`29.37.0`) from
`https://prometheus-community.github.io/helm-charts`.

## Files

| File | Description |
|---|---|
| `values.yaml` | Chart values for the server, Alertmanager, and Pushgateway |
| `deploy` | Deploy script (repo, helm install) |

## Architecture

- **Version pin**: `VERSION="29.37.0"` in `deploy`. Renovate tracks this pin
  through a custom manager in `cluster/helm/renovate/values.yaml`.

## Deployment

    cd cluster/helm/prometheus
    ./deploy

The script:
1. Adds the `prometheus-community` Helm repo only if it is not configured. It
   does not run `helm repo update`.
2. Runs `helm upgrade --install prometheus` with `values.yaml` and
   `--version 29.37.0` into namespace `monitoring`

To change the chart version, edit `VERSION` in `deploy`, run `make helm-update`
from the repository root, then run `./deploy`.

## Secrets

None. This directory contains no SOPS files.

## Verification

    kubectl -n monitoring get deploy,statefulset,svc | grep prometheus
    kubectl -n monitoring rollout status deploy/prometheus-server
    helm list -n monitoring

Check that:
- `rollout status` reports `successfully rolled out`
- `kube-state-metrics` and `prometheus-node-exporter` pods are `Running`
- `helm list` shows `prometheus` at chart `prometheus-29.37.0`
