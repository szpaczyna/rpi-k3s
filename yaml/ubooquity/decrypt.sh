#!/bin/bash
sops -d \
    --output 02-configmap.yaml \
    ../../secrets/ubooquity-config.yaml
