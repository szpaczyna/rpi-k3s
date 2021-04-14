#!/bin/bash
sops -d ../../secrets/kibana-secret.yaml > 00-kibana-auth.yaml
