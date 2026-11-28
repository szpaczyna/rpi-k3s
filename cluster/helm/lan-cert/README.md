# lan-cert

Issues and renews a Let's Encrypt wildcard certificate for `*.lan.shpaq.org`
and stores it in Secret `wildcard-lan-tls` in namespace `traefik`, where the
`websecure` listener of `traefik-internal` serves it by SNI.

`lan.shpaq.org` has no public A records, so the only usable challenge is
DNS-01. A weekly CronJob runs [lego](https://go-acme.github.io/lego/) with the
[`hurricane`](https://go-acme.github.io/lego/dns/hurricane/) provider, which
writes the challenge into the dynamic TXT record
`_acme-challenge.lan.shpaq.org` at dns.he.net. cert-manager is not involved.

| | |
|---|---|
| namespace | `traefik` |
| release | `lan-cert` |
| schedule | Monday 04:17 (`schedule` in `values.yaml`) |
| state | PVC `lan-cert-data` (Longhorn, 1Gi): ACME account key, certificates, resource JSON |
| token Secret | `lan-cert-hurricane`, key `tokens`, from `hurricane-token.enc.yaml` |
| target Secret | `wildcard-lan-tls`, type `kubernetes.io/tls` |

## How a run works

1. Init container `lego` runs `lego run`. With no stored certificate it
   obtains one; otherwise it renews when fewer than 30 days remain, or earlier
   if the CA's renewal info (ARI) asks for it. A run with nothing to do exits
   0 without contacting HE.
2. Container `update-secret` writes `tls.crt` and `tls.key` into
   `wildcard-lan-tls` with `kubectl apply --server-side`. An unchanged
   certificate produces no change to the Secret.

lego queries `1.1.1.1` and `8.8.8.8` for propagation checks. The cluster
resolver forwards to Pi-hole, which answers `lan.shpaq.org` locally and would
never see the public TXT record.

The Role allows `get`, `patch` and `update` on `wildcard-lan-tls` only. RBAC
cannot restrict `create` to one name, so `deploy` creates the Secret once with
a self-signed placeholder (`CN=placeholder`, valid one day). Traefik does not
select the placeholder, because `placeholder` matches no hostname.

## One-time HE setup

1. In dns.he.net, zone `shpaq.org`, the TXT record
   `_acme-challenge.lan.shpaq.org` must exist with "Enable entry for dynamic
   DNS" checked. Any initial value works.
2. Generate a DDNS key with the key icon next to the record.
3. Create the token Secret and encrypt it from the main checkout, which holds
   `.sops.yaml`:

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: lan-cert-hurricane
     namespace: traefik
   type: Opaque
   stringData:
     tokens: lan.shpaq.org:<ddns-key>
   ```

   ```sh
   sops -e -i hurricane-token.enc.yaml
   ```

## First run

```sh
./deploy
kubectl -n traefik create job --from=cronjob/lan-cert lan-cert-manual
kubectl -n traefik logs -f job/lan-cert-manual -c lego
kubectl -n traefik logs job/lan-cert-manual -c update-secret
kubectl -n traefik delete job lan-cert-manual
```

Run `./deploy` here before `../traefik-internal/deploy`. The Gateway drops the
whole `websecure` listener when a referenced Secret is missing, so
`traefik-internal/deploy` stops if `wildcard-lan-tls` does not exist yet.

## Staging and production

`acme.server` points at the Let's Encrypt production directory. To test a
change without touching production rate limits, set it to
`https://acme-staging-v02.api.letsencrypt.org/directory`, run `./deploy` and
start a manual Job.

The template names the stored certificate after the ACME server host, so the
production run finds no stored certificate and obtains a new one instead of
keeping the staging one until its renewal date.

## Rotating the token

1. Generate a new DDNS key for the TXT record in dns.he.net. The old key stops
   working.
2. `sops hurricane-token.enc.yaml`, replace the value after `lan.shpaq.org:`.
3. `./deploy`. The next Job mounts the new Secret.

## Verify

```sh
kubectl -n traefik get secret wildcard-lan-tls -o jsonpath='{.data.tls\.crt}' \
  | base64 -d | openssl x509 -noout -issuer -subject -enddate
openssl s_client -connect 10.0.0.50:443 -servername grafana.lan.shpaq.org </dev/null 2>/dev/null \
  | openssl x509 -noout -issuer -subject -enddate
```

On staging the issuer starts with `(STAGING)`; on production it is a Let's
Encrypt intermediate without that prefix. A second manual Job is a no-op: lego
logs `Skip renewal` and the Secret keeps the same certificate serial.

`x509-certificate-exporter` watches `kubernetes.io/tls` Secrets in every
namespace, so `wildcard-lan-tls` gets an expiry metric without extra
configuration.
