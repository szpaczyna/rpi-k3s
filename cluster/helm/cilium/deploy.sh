#!/bin/bash
helm upgrade --install cilium cilium/cilium -n kube-system -f values.yaml
