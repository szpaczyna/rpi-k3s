# Gentoo distcc

Retired and not deployed. This chart lives in `unused/`, nothing runs it, and no
build client in this repo points at it.

It was a distcc build node: a Gentoo container that accepted compile jobs on TCP
port `3632`, exposed on the LAN at `10.0.0.44`.

## What it was

| Item | Value |
|---|---|
| Image | `ksmanis/gentoo-distcc:tcp` |
| Workload | StatefulSet, 1 replica, scheduled on worker nodes |
| Service | `LoadBalancer` pinned to `10.0.0.44`, port `3632` |
| Storage | 8 Gi Longhorn PVC mounted at `/mnt` |
| Namespace | `apps` |
| Resources | 100m CPU and 100Mi memory requested, 3000m CPU and 2048Mi memory limit |

## What replaced it

Nothing in this repo replaces it. The Ansible `gentoo_portage` role manages
Portage configuration on Gentoo hosts, but no file outside `unused/` and the
changelog mentions distcc.

The chart was added in commit `c73ea24` (Aug 17, 2026) and moved to `unused/`
in commit `5d8e42e` (Aug 22, 2026). Neither commit records a reason.

## Before reviving

`10.0.0.44` sits inside the MetalLB `k3s-services` pool (`10.0.0.40-10.0.0.50`).
The pool auto-assigns addresses, and the chart's pin does not reserve this one.
No Service held `10.0.0.44` on the cluster on Oct 18, 2026, but check again
before deploying.

## Related

- [gentoo-manifests](../gentoo-manifests): a raw-manifest copy of the same Service and StatefulSet, with the same IP.
- [Repository README](../../../../README.md)
