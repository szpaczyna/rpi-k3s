#!/bin/bash
sops -d --output  01-secret.yaml ../../secrets/metallb.yaml
