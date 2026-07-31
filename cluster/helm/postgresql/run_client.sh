#!/bin/bash
POSTGRES_PASSWORD=$(kubectl get secret --namespace apps morphine-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
export POSTGRES_PASSWORD
kubectl run morphine-postgresql-client \
    --rm --tty -i \
    --restart='Never' \
    --namespace apps \
    --image docker.io/postgres:18.4 \
    --env="PGPASSWORD=$POSTGRES_PASSWORD" \
    --command -- psql \
    --host morphine-postgresql \
    --username postgres \
    --port 5432
