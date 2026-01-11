#!/bin/bash

# Check if jetstack repo is already added
if ! helm repo list | grep -q "jetstack"; then
    echo "Adding jetstack Helm repository..."
    helm repo add jetstack https://charts.jetstack.io
else
    echo "jetstack repository already exists"
fi

# Update helm repositories
helm repo update

## Install or upgrade cert-manager with custom values
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --values values.yaml \
  --version v$1
  
# Apply Let's Encrypt ClusterIssuers after a short delay to ensure cert-manager is ready
sleep 60; echo 'Waiting for containers to be created'
kubectl apply -f letsencrypt-staging.yaml -f letsencrypt-production.yaml --validate=false
