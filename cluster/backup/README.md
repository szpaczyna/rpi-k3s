# k3s backup

CronJob `k3s-backup` in `kube-system` runs daily at 02:01 on the control
plane. It takes a `VACUUM INTO` snapshot of the k3s SQLite datastore
(`/k3s/server/db/state.db`), checks it with `PRAGMA quick_check`, and writes
`<yyyymmddHHMM>.tar.gz` with `db/state.db` and `token` to
`/data/nfs/k3s-backups`. After a successful run the job deletes archives older
than 14 days.

    make backup

## NFS marker

Every backup job writes only when a `.backup-target` file exists in its
target directory on the NFS share exported by `rpi-k3s-worker-00`:

| Job | Directory |
|---|---|
| `k3s-backup` | `/data/nfs/k3s-backups` |
| `postgres-backup`, `postgres-full-backup` | `/data/nfs/postgres-backups` |
| `grafana-backup-tool` | `/data/nfs/grafana-backups` |

The deploy scripts do not create the marker. A local directory left on a node
by an unmounted share has no marker, so the job fails instead of filling the
node's disk. After you replace the disk or recreate the share, create the
markers once on `rpi-k3s-worker-00`:

    touch /data/nfs/{k3s,postgres,grafana}-backups/.backup-target

## Restore

The archive holds the datastore and the token that encrypts its bootstrap
data. k3s needs both.

On the control plane:

    systemctl stop k3s
    mv /k3s/server/db /k3s/server/db.old
    cp /k3s/server/token /k3s/server/token.old
    tar -xzf /data/nfs/k3s-backups/<archive>.tar.gz -C /k3s/server
    systemctl start k3s

Moving `db` aside also removes the old `state.db-wal` and `state.db-shm`,
which do not belong to the restored `state.db`. k3s turns WAL mode back on
when it starts.

A test with k3s v1.37.1+k3s1 backed up a running server with this job's script
and restored the archive into an empty data dir. k3s started on it with its
ConfigMaps and Secrets intact.
