# cert-manager

Issues TLS certificates from Let's Encrypt for the cluster, deployed with the
upstream chart `jetstack/cert-manager` (`v1.21.1`) from `https://charts.jetstack.io`.

## Files

| File | Description |
|---|---|
| `values.yaml` | Chart values: CRDs, Gateway API, resource limits, metrics annotations, ACME solver nameservers |
| `deploy` | Deploy script (repo, namespace, helm install, issuers) |
| `letsencrypt-staging.yaml` | ClusterIssuer `letsencrypt-stage` (Let's Encrypt staging). Applied by `deploy` |
| `letsencrypt-production.yaml` | ClusterIssuer `letsencrypt-prod` (Let's Encrypt production). Applied by `deploy` |
| `prometheus-rule.yaml` | PrometheusRule `cert-manager.rules`. Applied manually |
| `letsencrypt-podMonitor.yaml` | PodMonitor `cert-manager`. Applied manually |

## Architecture

- **Issuers**: both ClusterIssuers use ACME HTTP-01 with a Gateway API solver.
  Challenges attach to the Gateway `traefik-gateway`.
- **Default issuer**: `ingressShim.defaultIssuerName` is `letsencrypt-prod`.
- **Gateway API**: enabled through `config.enableGatewayAPI`.
- **CRDs**: installed by the chart, with `crds.keep: true` so they survive a
  chart uninstall.
- **Solver DNS**: `--acme-http01-solver-nameservers=10.0.0.2:53` is passed to
  the controller.
- **Version pin**: `VERSION="v1.21.1"` in `deploy`, with the `v` prefix included.

## Deployment

    cd cluster/helm/cert-manager
    ./deploy

The script:
1. Adds the `jetstack` Helm repo only if it is not configured. It does not run
   `helm repo update`.
2. Creates namespace `cert-manager` if it is missing.
3. Runs `helm upgrade --install` with `values.yaml` and `--version v1.21.1`.
4. Sleeps 60 seconds, then applies `letsencrypt-staging.yaml` and
   `letsencrypt-production.yaml` with `--validate=false`.

The 60-second sleep is a fixed wait, not a readiness check. If the issuer apply
fails, rerun `./deploy` once the webhook pod is `Running`.

To change the chart version, edit `VERSION` in `deploy`, run `make helm-update`
from the repository root, then run `./deploy`.

## Manual steps

The deploy script does not apply these two files:

    kubectl apply -f prometheus-rule.yaml
    kubectl apply -f letsencrypt-podMonitor.yaml

## Secrets

None. This directory contains no SOPS files. cert-manager creates the ACME
account keys in the Secrets `staging-issuer-account-key` and
`prod-issuer-account-key`.

## Verification

    kubectl -n cert-manager rollout status deploy/cert-manager
    kubectl get clusterissuer letsencrypt-stage letsencrypt-prod
    helm list -n cert-manager

Check that:
- `rollout status` reports `successfully rolled out`
- both ClusterIssuers show `READY` as `True`
- `helm list` shows `cert-manager` at chart `cert-manager-v1.21.1`
