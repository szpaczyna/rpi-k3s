#!/bin/bash

#helm repo add influxdata https://helm.influxdata.com/
#helm repo update
sops -d ../../secrets/influxdb-auth.yaml > secret.yaml
kubectl apply -f ./secret.yaml

helm upgrade --install influxdb influxdata/influxdb -n apps -f ./values.yaml
rm -rf secret.yaml
