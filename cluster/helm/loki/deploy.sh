#!/bin/bash
#helm repo add grafana https://grafana.github.io/helm-charts
#helm repo update

helm upgrade --install loki --namespace=logging grafana/loki-stack -f values.yaml
