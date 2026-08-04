# Gateway API

Installs the Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/)
CRDs (standard channel), required by:

- Traefik's `kubernetesGateway` provider (see
  [`cluster/helm/traefik`](../../helm/traefik)) — Traefik's Helm chart no
  longer bundles these CRDs (removed upstream since chart v40.2.0).
- cert-manager's `gatewayHTTPRoute` ACME HTTP-01 solver (see
  [`cluster/helm/cert-manager`](../../helm/cert-manager)).

## Usage

```bash
./deploy
```

Downloads the pinned `standard-install.yaml` release manifest from the
upstream `kubernetes-sigs/gateway-api` GitHub releases and applies it with
server-side apply (`--force-conflicts`, since these CRDs may already be
present on the cluster from a prior installation with a different field
manager).

To upgrade, bump `GATEWAY_API_VERSION` in `deploy` and re-run — it will
re-download and re-apply the new manifest, taking ownership of any
changed fields.

## What's installed

Standard channel only: `GatewayClass`, `Gateway`, `HTTPRoute`,
`GRPCRoute`, `ReferenceGrant`, `BackendTLSPolicy`. No experimental-channel
resources (`TCPRoute`, `UDPRoute`, `TLSRoute`) — not needed, all traffic
on this cluster is HTTP/HTTPS.
