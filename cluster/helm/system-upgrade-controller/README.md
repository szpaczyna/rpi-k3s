# System Upgrade Controller

Rancher's System Upgrade Controller (SUC) for K3s. It runs in namespace
`system-upgrade` and reconciles two `Plan` objects that upgrade the cluster one node
at a time. Upgrades are driven by the version passed to [`deploy`](deploy).

## Plans

| Plan | Selects | Behaviour |
|---|---|---|
| `k3s-server-plan` | `node-role.kubernetes.io/control-plane` is `true` | Concurrency 1, cordon |
| `k3s-agent-plan` | Nodes without the control-plane label | Concurrency 1, cordon, drain with `force: true` and `skipWaitForDeleteTimeout: 60` |

Both plans use the `rancher/k3s-upgrade` image at the version in `k3sVersion`. The
agent plan's `prepare` step names `k3s-server-plan`, so agents upgrade after servers.

Upgrade Jobs run privileged. The `SYSTEM_UPGRADE_JOB_PRIVILEGED` setting in
`values.yaml` controls this. Upstream SUC runs these Jobs with host IPC, network
and PID namespaces, and with the host root filesystem mounted.

## Deploying a version

```sh
cd cluster/helm/system-upgrade-controller
./deploy v1.37.1+k3s1
```

The argument is required. `deploy` passes it as `k3sVersion`, which becomes the
`version` on both Plans. The kubectl image the upgrade Jobs use is derived from the
same version with the `+k3sN` and `-` suffixes removed. `v1.37.1+k3s1` gives
`rancher/kubectl:v1.37.1`.

The `k3sVersion` default in `values.yaml` applies only to a bare `helm install` with
no version argument. CI installs the chart into a kind cluster that way.

`plan.channel` is set to the stable K3s channel, but it is not used. Upstream SUC
skips channel resolution when a Plan sets `version`, and this chart sets it in both Plans.

## Job and controller settings

These values are passed to the controller as the `default-controller-env` ConfigMap.

| Variable | Value | Meaning |
|---|---|---|
| `SYSTEM_UPGRADE_CONTROLLER_THREADS` | `2` | Worker threads |
| `SYSTEM_UPGRADE_JOB_ACTIVE_DEADLINE_SECONDS` | `900` | Time limit for one upgrade Job |
| `SYSTEM_UPGRADE_JOB_BACKOFF_LIMIT` | `99` | Retries before a Job is marked failed |
| `SYSTEM_UPGRADE_JOB_TTL_SECONDS_AFTER_FINISH` | `900` | Cleanup delay for finished Jobs |
| `SYSTEM_UPGRADE_PLAN_POLLING_INTERVAL` | `15m` | How often Plans are re-evaluated |
| `SYSTEM_UPGRADE_JOB_IMAGE_PULL_POLICY` | `Always` | Pull policy for upgrade Job images |
| `SYSTEM_UPGRADE_JOB_PRIVILEGED` | `true` | Run upgrade Jobs privileged |

The controller itself is scheduled only on control-plane nodes. It tolerates
`CriticalAddonsOnly` and the control-plane `NoSchedule` taint. Its Deployment uses
the `Recreate` strategy, because two controllers reconciling the same Plans would
compete for the same upgrade Jobs.

## CRD

`crds/plans.yaml` installs the `plans.upgrade.cattle.io` CRD. Helm installs CRDs
from `crds/` on the first install only and does not upgrade them. A change to the
CRD needs a manual `kubectl apply -f crds/plans.yaml`.

## Verifying

```sh
kubectl -n system-upgrade get plans
kubectl -n system-upgrade get jobs
kubectl -n system-upgrade logs deploy/system-upgrade-controller
```

The `plans` output shows the image, channel, target version and completion status
for each Plan.
