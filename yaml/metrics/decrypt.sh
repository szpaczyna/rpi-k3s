#!/bin/bash
sops -d --output  ingress/promethus-auth.yaml ../../secrets/prometheus-secret.yaml
