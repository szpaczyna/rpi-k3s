#!/bin/bash

# Install helm-secrets plugin with specified version
# Usage: ./install_helm_secrets.sh [VERSION]
# Example: ./install_helm_secrets.sh v4.7.4

VERSION="${1:-v4.7.5}"

echo "Installing helm-secrets version ${VERSION}..."

helm plugin install --verify=false https://github.com/jkroepke/helm-secrets/releases/download/${VERSION}/secrets-${VERSION#v}.tgz
helm plugin install --verify=false https://github.com/jkroepke/helm-secrets/releases/download/${VERSION}/secrets-getter-${VERSION#v}.tgz
helm plugin install --verify=false https://github.com/jkroepke/helm-secrets/releases/download/${VERSION}/secrets-post-renderer-${VERSION#v}.tgz

echo "helm-secrets ${VERSION} installed successfully!"
