# Helm chart

Installs Gitea standalone version.

# Installing chart

    cd <path-to-repo>
    ./decrypt.sh
    helm install -n <my-namespace> gitea -f values.yaml .

or use a deploy script

    ./deploy

# Notes

values.yaml is encrypted with sops.
