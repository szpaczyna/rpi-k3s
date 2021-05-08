#!/bin/bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace apps morphine-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
kubectl run morphine-postgresql-client \
    --rm --tty -i \
    --restart='Never' \
    --namespace apps \
    --image docker.io/postgres:13 \
    --env="PGPASSWORD=$POSTGRES_PASSWORD" \
    --command \ 
    -- psql --host morphine-postgresql \
    -U postgres -p 5432 \
    -d $1
