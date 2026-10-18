# shpaq.org

Public landing page for `shpaq.org`. A static nginx pod serves one HTML page and a
`robots.txt`, both stored in the chart's ConfigMap. Deployed into namespace `apps`
by [`deploy`](deploy) under release `shpaq-org`.

## Where the page lives

The HTML is inline in [`templates/configmap.yaml`](templates/configmap.yaml), and
that is what the pod serves. `files/index.html` is not referenced by any template,
so editing it changes nothing on the cluster.

## Request path

1. Gateway `traefik-gateway` in `traefik`, section `websecure`. Traefik terminates TLS here.
2. HTTPRoute `shpaq-org` in `apps`, hostname `shpaq.org`, path prefix `/`.
3. Middleware `security-chain-nogeo` in `apps` (set by `httpRoute.securityChainMiddleware`).
4. Service `shpaq-org` on port `80`, to the nginx container on port `80`.

The chain is `nogeo`, so it has `redirect-https`, `hsts` and `compress`, and no
`geoblock`. The repository does not record why the landing page skips `geoblock`.

### TLS

The chart renders a cert-manager Certificate, `shpaq-org-tls`, into namespace
`traefik`. It is issued by the ClusterIssuer `letsencrypt-prod` for `shpaq.org`.
The Gateway can only reference Secrets in its own namespace, so the Certificate
lives there too. The secret name must also appear in
`gateway.listeners.websecure.certificateRefs` in
[`traefik-external/values.yaml`](../traefik-external/values.yaml). The chart does
not add that entry.

Other `*.shpaq.org` names are not served by this chart. A route in `traefik-external`
redirects them to `https://shpaq.org`.

## Workload

| Setting | Value |
|---|---|
| Image | `nginx:1.31.7` |
| Replicas | 1, `Recreate` strategy (each rollout has a short gap) |
| Requests / limits | CPU `8m` / `24m`, memory `8Mi` / `64Mi` |
| Autoscaling | CPU HPA at 80% average utilization, 1 to 2 replicas. Memory HPA is disabled |
| Node placement | `nodeSelector: kubernetes.io/role: worker` |

## Deploying

```sh
cd cluster/helm/shpaq-org
./deploy
```

The script runs `helm upgrade --install` with `values.yaml` and `--create-namespace`.

## Verifying

```sh
kubectl -n apps get deploy,hpa,svc,httproute
kubectl -n traefik get certificate shpaq-org-tls
curl -sI https://shpaq.org | head -1
```

The last command should print `HTTP/2 200`. The Certificate should show `Ready=True`.
