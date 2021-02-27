#!/bin/bash
sops -d \
    --output templates/secret.yaml \
    ../../secrets/pihole.yml
