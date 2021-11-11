#!/bin/bash
kubectl run \
    -it \
    --rm cockroach-client \
    --image=registry.shpaq.org/cockroachdb:v20.2.8 \
    --restart=Never \
    --command -- \
    ./cockroach sql --insecure --host cockroachdb
