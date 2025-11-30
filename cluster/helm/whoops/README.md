# Whoops Helm Chart

This Helm chart deploys the [Whoops](https://github.com/kryoseu/whoops) application on a Kubernetes cluster.

## Prerequisites

This chart requires a running PostgreSQL database. The chart does not create or manage the database. You must provide the database connection details in the `values.yaml` file.

## Application Source Code

The source code for the application can be found at: [https://github.com/kryoseu/whoops](https://github.com/kryoseu/whoops)

## Docker Image

The Docker image for this chart was built using the following command (`arm64` image). For `amd64` please use upstream image.

```bash
docker buildx build --file Dockerfile --label=build-by=shpaq --push --platform linux/arm64 -t szpaczyn/whoops:0.2.4 .
```

## Installation

To install the chart with the release name `my-whoops`:

```bash
helm install my-whoops . --namespace apps
```

## Configuration

A sample `values.yaml` is provided below:

```yaml
replicaCount: 1

image:
  repository: szpaczyn/whoops
  pullPolicy: Always
  tag: "0.2.4"

service:
  type: ClusterIP
  port: 5000

ingress:
  enabled: true
  className: "nginx"
  host: whoops.shpaq.org
  tls: true
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/auth-realm: Authentication Required
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/auth-secret: whoops-auth
auth:
  secretName: whoops-auth
  data: "user:password"

env:
  CLIENT_ID: ""
  CLIENT_SECRET: ""
  SQLALCHEMY_DATABASE_URI: "postgresql+psycopg2://USER:PASSWORD@DB_HOST:DB_PORT/DATABASE"
```
