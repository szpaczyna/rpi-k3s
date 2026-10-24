# PostgreSQL

Shared PostgreSQL 18 instance for apps in namespace `apps`, deployed with the
chart `groundhog2k/postgres` from `https://groundhog2k.github.io/helm-charts/`.
The Helm release is named `morphine`, and the Service is `morphine-postgresql`.

## Files

| File | Description |
|---|---|
| `values-public.yaml` | Non-sensitive chart config (image, Service name, security context) |
| `values.enc.yaml` | Sensitive chart config. SOPS encrypted |
| `deploy` | Deploy script (repo, helm install, backup jobs) |
| `backup-job.yaml` | CronJob `postgres-backup`, runs daily at 02:00. Dumps `grafana`, `bitwarden`, `gitea`, `whoops` |
| `backup-full-job.yaml` | CronJob `postgres-full-backup`, runs daily at 01:00 |
| `pgpass.enc.yaml` | Encrypted Secret for the backup jobs. Not applied by `deploy` |
| `databases.enc.sql` | SOPS-encrypted SQL file. Not applied by `deploy` |
| `run_client.sh` | Opens an interactive `psql` session from a throwaway pod |

## Architecture

- **Image**: `postgres:18.6` in `values-public.yaml`, `backup-job.yaml`,
  `backup-full-job.yaml`, and `run_client.sh`. The chart's appVersion is also
  `18.6`. Change all four image references together.
- **Service name**: `fullnameOverride` sets the Service to `morphine-postgresql`.
  Apps connect to that name.
- **Backups**: both CronJobs read `PGPASS` from Secret `postgresql-pgpass`
  (key `pgpass`). The full backup also mounts the volume `postgres-storage`.
- **Version pin**: `VERSION="1.6.8"` in `deploy`.

## Deployment

    cd cluster/helm/postgresql
    ./deploy

The script:
1. Adds the `groundhog2k` Helm repo only if it is not configured. It does not
   run `helm repo update`.
2. Runs `helm upgrade --install morphine` with `values-public.yaml` and
   `values.enc.yaml` (via `sops -d`) into namespace `apps`
3. Applies `backup-job.yaml` and `backup-full-job.yaml`

The `pgpass.enc.yaml` apply line in `deploy` is commented out.

To change the chart version, edit `VERSION` in `deploy`, run `make helm-update`
from the repository root, then run `./deploy`.

## Secrets

`values.enc.yaml` and `pgpass.enc.yaml` live next to the chart. To edit:

    sops ./values.enc.yaml
    sops ./pgpass.enc.yaml

To view without editing:

    sops -d ./values.enc.yaml

## Manual steps

Before the first backup run, check that Secret `postgresql-pgpass` exists:

    kubectl -n apps get secret postgresql-pgpass

If it does not exist, apply it:

    kubectl apply -f <(sops -d ./pgpass.enc.yaml) -n apps

## Verification

    kubectl -n apps get pods,svc,cronjob | grep -E 'morphine|postgres'
    helm list -n apps
    ./run_client.sh

Check that:
- a `morphine-postgresql` pod is `Running` and `Ready`
- the Service `morphine-postgresql` exists in `apps`
- CronJobs `postgres-backup` and `postgres-full-backup` are listed
- `helm list` shows `morphine` with status `deployed`
- `\l` at the `psql` prompt lists the databases that the backup job dumps
