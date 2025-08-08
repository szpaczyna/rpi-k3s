# Photoprism Helm Chart
Helm chart to install [PhotoPrism](https://photoprism.org/).

PhotoPrism is a server-based application for browsing, organizing, and sharing your personal photo collection.

## Config
PhotoPrism's configuration can be passed in through environment variables.
To see what is available, you can consult
https://github.com/photoprism/photoprism/blob/develop/docker-compose.yml
or run `docker run photoprism/photoprism photoprism config` to see all possible values.

Note: storage and database configuration, as well as the admin password, should be set
in their appropriate configuration sections. They should not be set here.


## Persistence

It's important to configure persistent storage (e.g., NFS) for any sort of real-world usage.

I've been running PhotoPrism using two NFS shares: one for PhotoPrism's storage cache, and one pointing to where I store my original images in Lightroom (read-only).
This has been working well for me; keeping PhotoPrism assets separate keeps my Lightroom workspace ~~uncluttered~~ less cluttered ;)

If you don't enable persistence, you can still take PhotoPrism for a spin; you'll just have to start from scratch if the pod dies and gets scheduled on a different node.

Note: You can utilize the subPath option of a `volueMount` to only expose a portion of your photo collection. I personally do this, in conjuction with
custom ingress hosts and `PHOTOPRISM_PUBLIC=true`, to share specific galleries with friends with a simple URL (e.g., my-wedding.mydomain.com)


## Database

PhotoPrism can be run without any external dependencies. If no remote database is provided, PhotoPrism will
run SQLite internally. If you enabled persitent storage and specify a value for `persistence.storagePath`, this chart
will automatically configure the SQLite database file to be written to the persistent storage path.

Alternately, if you prefer to run the database separately, you can point PhotoPrism at a MySQL-compatible database
instance (e.g., MySQL, MariaDB, Percona)

## Accessing PhotoPrism

The default values will only expose PhotoPrism inside your cluster on port 80. Some options for accessing PhotoPrism from outside your cluster:
- Configure ingress rules for use with a reverse proxy
- Change the service type to `NodePort` and pick a [free port to expose](https://kubernetes.io/docs/concepts/services-networking/service/)
- Access it from your client with [kubectl port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)
