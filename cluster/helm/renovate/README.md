# Renovate

Self-hosted Renovate bot that opens dependency update PRs for this repository.
It runs as a CronJob and uses the OCI chart
`oci://ghcr.io/renovatebot/charts/renovate` (`46.366.3`). No Helm repo is added.

## Files

| File | Description |
|---|---|
| `values.yaml` | Chart values: platform, schedule, `customManagers` for chart pins |
| `deploy` | Deploy script (secret, helm install) |
| `secret.enc.yaml` | Secret `renovate-env` (token, repository list, Docker host rules). SOPS encrypted |

## Architecture

- **Platform**: GitHub (`RENOVATE_PLATFORM: github`).
- **Schedule**: CronJob `0 23 * * 4` (Thursdays at 23:00), with
  `concurrencyPolicy: Forbid`.
- **Credentials**: `existingSecret: renovate-env` points the chart at the
  Secret. The chart does not render credentials.
- **Version pin**: `VERSION="46.366.3"` and `CHART="oci://..."` in `deploy`.
- **Custom managers**: `renovate.config` in `values.yaml` holds regex managers
  that read `VERSION` from the `deploy` scripts of cert-manager, grafana,
  prometheus, renovate, authelia, traefik, loki, metallb, postgresql, and
  longhorn. Built-in managers cannot
  see these shell variables. Add a manager when a new `deploy` script pins a
  chart version.

## Deployment

    cd cluster/helm/renovate
    ./deploy

The script:
1. Applies `secret.enc.yaml` (via `sops -d`) before Helm runs
2. Runs `helm upgrade --install` with `values.yaml` and `--version 46.366.3`,
   from the OCI registry

This chart has no Helm repo, so `make helm-update` does not apply. After a pin
change, edit `VERSION` in `deploy` and run `./deploy`.

## Secrets

`secret.enc.yaml` lives next to the chart. To edit:

    sops ./secret.enc.yaml

To view without editing:

    sops -d ./secret.enc.yaml

After rotating the token, run `./deploy` again. The chart does not restart
running pods when `existingSecret` changes. The next scheduled Job picks up the
new value.

## Verification

    kubectl -n renovate get cronjob,pods
    helm list -n renovate

Check that:
- the CronJob in `renovate` shows `SCHEDULE` `0 23 * * 4`
- the last Job completed without errors (`kubectl -n renovate logs job/<name>`)
- `helm list` shows `renovate` at chart `renovate-46.366.3`
