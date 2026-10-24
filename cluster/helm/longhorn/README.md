# Longhorn

Distributed block storage for the cluster, deployed with the upstream chart
`longhorn/longhorn` (`1.12.1`) from `https://charts.longhorn.io`.

## Files

| File | Description |
|---|---|
| `values.yaml` | Chart values, including `storageNodes.exclude` and `defaultSettings` |
| `deploy` | Deploy script (repo, auth Secret, helm install, node scheduling patch). Takes an optional chart version argument |
| `auth.enc.yaml` | Longhorn UI basic-auth Secret. SOPS encrypted |
| `decrypt` | Writes the decrypted auth Secret to `longhorn-auth.yaml` in the current directory |
| `cleanup.sh` | Deletes Longhorn CRD instances in `longhorn-system` and waits for each to clear. Destructive |

## Architecture

- **Chart version**: `VERSION="1.12.1"` in `deploy` pins the chart. An argument
  overrides it for one run: `./deploy 1.12.2`.
- **Control-plane node**: `rpi-k3s-master-00` is listed under
  `storageNodes.exclude`. The chart cannot set `allowScheduling` per node, so
  `deploy` patches the `nodes.longhorn.io` CR after the install.
- **Auth**: the UI sits behind basic auth, provided by the `auth.enc.yaml`
  Secret.

## Deployment

    cd cluster/helm/longhorn
    ./deploy            # installs the VERSION pinned in deploy
    ./deploy 1.12.2     # installs a different chart version for this run

The script:
1. Resolves the chart version from the argument or the `VERSION` pin
2. Adds the `longhorn` Helm repo only if it is not configured. It does not run
   `helm repo update`.
3. Applies `auth.enc.yaml` (via `sops -d`) into `longhorn-system`, before Helm runs
4. Runs `helm upgrade --install` with `values.yaml` and `--version`
5. Patches `spec.allowScheduling: false` on each node in `storageNodes.exclude`

Step 5 is idempotent. It pins the field on each run.

To change the pinned version, edit `VERSION` in `deploy`, run `make helm-update`
from the repository root, then run `./deploy`.

## Secrets

`auth.enc.yaml` is SOPS encrypted. To edit:

    sops ./auth.enc.yaml

`decrypt` writes plaintext to `longhorn-auth.yaml` in the working directory.
Delete that file after use.

## Verification

    kubectl -n longhorn-system get pods
    kubectl -n longhorn-system get nodes.longhorn.io \
      -o custom-columns=NAME:.metadata.name,ALLOW:.spec.allowScheduling
    helm list -n longhorn-system

Check that:
- all pods in `longhorn-system` are `Running` or `Completed`
- `rpi-k3s-master-00` shows `ALLOW` `false`
- other nodes show `ALLOW` `true`
- `helm list` shows `longhorn` at chart `longhorn-1.12.1`
