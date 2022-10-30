#!/bin/bash
#kubectl create namespace cert-manager
#kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
#kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.6.0/cert-manager.yaml
#helm repo add jetstack https://charts.jetstack.io
#helm repo update

helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.10.0 \
  --set installCRDs=true \
  --set prometheus.enabled=true

#sleep 60; echo 'Waiting for containers to be created'
kubectl apply -f letsencrypt-staging.yaml -f letsencrypt-production.yaml --validate=false
