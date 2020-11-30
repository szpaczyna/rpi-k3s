#!/bin/bash
kubectl -n kube-system scale deployment traefik --replicas=5
