# MetalLB

Load balancer for bare-metal services. It hands out LAN addresses to
`LoadBalancer` Services, using the upstream chart `metallb/metallb` (`0.16.2`)
from `https://metallb.github.io/metallb`.

## Files

| File | Description |
|---|---|
| `values.yaml` | Chart values: CRDs, component settings |
| `deploy` | Deploy script (repo, helm install, `resources.yaml`) |
| `resources.yaml` | IPAddressPool `k3s-services` and L2Advertisement `l2advertisement1` |

## Architecture

- **Pool**: `k3s-services` (`10.0.0.40-10.0.0.50`) in `resources.yaml`, advertised
  through `l2advertisement1`. The upstream chart has no values for pools.
- **Version pin**: `VERSION="0.16.2"` in `deploy`. The image tags in
  `values.yaml` stay empty, so the chart uses its appVersion.

## Deployment

    cd cluster/helm/metallb
    ./deploy

The script:
1. Adds the `metallb` Helm repo only if it is not configured. It does not run
   `helm repo update`.
2. Runs `helm upgrade --install` with `values.yaml` and `--version 0.16.2`
3. Applies `resources.yaml`

To change the chart version, edit `VERSION` in `deploy`, run `make helm-update`
from the repository root, then run `./deploy`.

## Secrets

None. This directory contains no SOPS files.

## Known issues

- `values.yaml` has two top-level `crds:` keys (lines 10 and 365). Keep one block
  and confirm the result with `helm template metallb metallb/metallb -f values.yaml`
  before the next deploy.

## Verification

    kubectl -n metallb-system get pods
    kubectl -n metallb-system get ipaddresspools,l2advertisements
    kubectl get svc -A | grep LoadBalancer

Check that:
- all pods in `metallb-system` are `Running`
- the pool `k3s-services` is listed
- `l2advertisement1` exists
- a `LoadBalancer` Service has an `EXTERNAL-IP` inside one of the pool ranges
