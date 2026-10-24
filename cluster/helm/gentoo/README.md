# Gentoo distcc

Gentoo distcc build node: a Gentoo container that accepts compile jobs on TCP
port `3632`, exposed on the LAN at `10.0.0.44`. Deployed into namespace `apps`.

## Files

| File | Description |
|---|---|
| `values.yaml` | Chart values (image, Service, resources) |
| `deploy` | Deploy script (`helm upgrade --install`) |
| `templates/` | StatefulSet and Service |

## Deployment

    cd cluster/helm/gentoo
    ./deploy

## Notes

- `10.0.0.44` sits inside the MetalLB `k3s-services` pool (`10.0.0.40-10.0.0.50`).
  The pool auto-assigns addresses and the chart's pin does not reserve this one.
  Check that no Service holds `10.0.0.44` before deploying.
- Image: `ksmanis/gentoo-distcc:tcp`.
- Storage: 8 Gi Longhorn PVC mounted at `/mnt`.

## Related

- [Repository README](../../../../README.md)