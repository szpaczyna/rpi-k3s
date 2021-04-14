https://hub.docker.com/r/mrnr91/filebeat-alpine

```
args: ["--modules","traefik","-M", "traefik.access.var.paths=[/tmp/access.log]"]
additionalArguments:
  - "--accesslog=true"
  - "--accesslog.filepath=/tmp/access.log"

```

https://coralogix.com/log-analytics-blog/elasticsearch-logstash-kibana-on-kubernetes/
