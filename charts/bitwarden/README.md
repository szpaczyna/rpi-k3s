# Helm chart

Installs the project as a Deployment for Bitwarden community version.

# Installing chart

```
cd <path-to-repo>
./decrypt.sh
helm install -n <my-namespace> bitwarden -f values.yaml .
```

# Notes
values.yaml is encrypted with sops.
