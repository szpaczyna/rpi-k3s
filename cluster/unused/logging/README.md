## Notes
https://hub.docker.com/r/mrnr91/filebeat-alpine

```yaml
args: ["--modules","traefik","-M", "traefik.access.var.paths=[/tmp/access.log]"]
additionalArguments:
  - "--accesslog=true"
  - "--accesslog.filepath=/tmp/access.log"

```

https://coralogix.com/log-analytics-blog/elasticsearch-logstash-kibana-on-kubernetes/

```yaml
    - name: morphine
      protocol: layer2
      addresses:
      - 10.0.0.31-10.0.0.34
      avoid-buggy-ips: true
```
