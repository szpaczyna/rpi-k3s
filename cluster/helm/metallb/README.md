# MetalLB

Load balancer for bare-metal services. It hands out LAN addresses to
`LoadBalancer` Services, using the upstream chart `metallb/metallb` (`0.16.1`)
from `https://metallb.github.io/metallb`.

## Files

| File | Description |
|---|---|
| `values.yaml` | Chart values: CRDs, IP address pools (layer2 and BGP), BGP peers, component settings |
| `deploy` | Deploy script (repo, helm install, `resources.yaml`) |
| `resources.yaml` | IPAddressPool `k3s-services` and L2Advertisement `l2advertisement1` |

## Architecture

- **Pools in values.yaml**: `morphine` (layer2, `10.0.0.31-10.0.0.34`) and `bgp`
  (`10.1.0.2-10.1.0.254`), with `bgpPeers` and `bgpAdvertisements` in the same file.
- **Pool in resources.yaml**: `k3s-services` (`10.0.0.40-10.0.0.50`), advertised
  through `l2advertisement1`.
- **Version pin**: `VERSION="0.16.1"` in `deploy`. The MetalLB image tag
  `v0.16.1` is set in `values.yaml` in two places. Keep it in step with the pin.

## Deployment

    cd cluster/helm/metallb
    ./deploy

The script:
1. Adds the `metallb` Helm repo only if it is not configured. It does not run
   `helm repo update`.
2. Runs `helm upgrade --install` with `values.yaml` and `--version 0.16.1`
3. Applies `resources.yaml`

To change the chart version, edit `VERSION` in `deploy`, run `make helm-update`
from the repository root, then run `./deploy`.

## Secrets

None. This directory contains no SOPS files.

## Known issues

- `values.yaml` has two top-level `crds:` keys (lines 13 and 391). Keep one block
  and confirm the result with `helm template metallb metallb/metallb -f values.yaml`
  before the next deploy.

## Verification

    kubectl -n metallb-system get pods
    kubectl -n metallb-system get ipaddresspools,l2advertisements
    kubectl get svc -A | grep LoadBalancer

Check that:
- all pods in `metallb-system` are `Running`
- the pools `morphine`, `bgp`, and `k3s-services` are listed
- `l2advertisement1` exists
- a `LoadBalancer` Service has an `EXTERNAL-IP` inside one of the pool ranges
