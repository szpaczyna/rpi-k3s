# Grafana

Dashboards for the cluster, deployed with the upstream chart `grafana/grafana`
(`10.5.14`) from `https://grafana.github.io/helm-charts`.

## Files

| File | Description |
|---|---|
| `values.yaml` | Chart values: image, persistence on Longhorn, probes, deployment strategy, admin Secret reference |
| `deploy` | Deploy script (repo, namespace, secrets, backup CronJob, helm install) |
| `admin-creds.enc.yaml` | Admin credentials Secret, referenced as `grafana-admin-creds`. SOPS encrypted |
| `backup-secret.enc.yaml` | Secret used by the backup CronJob. SOPS encrypted |
| `backup-cronjob.yaml` | CronJob `grafana-backup-tool` in `monitoring`, runs daily at 04:03 |

## Architecture

- **Image**: `grafana/grafana:10.4.19-security-01`, set in `values.yaml`. The
  chart version (`10.5.14`) and the image tag are separate values.
- **Storage**: PVC on `storageClassName: longhorn`.
- **Rollout**: `deploymentStrategy: Recreate`, so the old pod stops before the
  new one starts on the same PVC.
- **Admin credentials**: `admin.existingSecret` points to `grafana-admin-creds`.
- **Backups**: CronJob `grafana-backup-tool` runs
  `szpaczyn/grafana-backup-tool:1.4.2` as UID 1337. The init container
  `fix-permissions` runs before it.
- **Probes**: liveness and readiness use `/api/health` on port 3000.

## Deployment

    cd cluster/helm/grafana
    ./deploy

The script:
1. Adds the `grafana` Helm repo only if it is not configured. It does not run
   `helm repo update`.
2. Creates namespace `monitoring` if it is missing.
3. Applies `admin-creds.enc.yaml` and `backup-secret.enc.yaml` (via `sops -d`)
   into `monitoring`, before Helm runs.
4. Applies `backup-cronjob.yaml`.
5. Runs `helm upgrade --install` with `values.yaml` and `--version 10.5.14`.

To change the chart version, edit `VERSION` in `deploy`, run `make helm-update`
from the repository root, then run `./deploy`.

## Secrets

The two `*.enc.yaml` files live next to the chart. To edit:

    sops ./admin-creds.enc.yaml
    sops ./backup-secret.enc.yaml

To view without editing:

    sops -d ./admin-creds.enc.yaml

## Verification

    kubectl -n monitoring rollout status deploy/grafana
    kubectl -n monitoring get cronjob grafana-backup-tool
    helm list -n monitoring

Check that:
- `rollout status` reports `successfully rolled out`
- the CronJob shows `SCHEDULE` `3 4 * * *` and `SUSPEND` `False`
- `helm list` shows `grafana` at chart `grafana-10.5.14`
