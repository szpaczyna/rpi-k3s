#!/bin/bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace apps morphine-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
kubectl run morphine-postgresql-client \
    --rm --tty -i \
    --restart='Never' \
    --namespace apps \
    --image docker.io/postgres:16.6.0 \
    --env="PGPASSWORD=$POSTGRES_PASSWORD" \
    --command -- psql \
    --host morphine-postgresql-read \
    --username postgres \
    --port 5432
