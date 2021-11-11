#!/bin/bash
sops -d \
    --output templates/secret.yaml \
    ../../secrets/pihole.yml
sops -d \
    --output templates/exporter_secret.yaml \
    ../../secrets/exporter_secret.yaml
