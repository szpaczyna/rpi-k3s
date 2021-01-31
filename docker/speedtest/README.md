# Speedtest CLI Prometheus Exporter

[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/billimek/prometheus-speedtest-exporter)](https://hub.docker.com/r/billimek/prometheus-speedtest-exporter/tags)

![](https://i.imgur.com/iIzWUre.png)

This is a docker container which runs a prometheus exporter to collect speedtest data using the official [Speedtest CLI](https://www.speedtest.net/apps/cli) and [script_exporter](https://github.com/ricoberger/script_exporter).  The [billimek/prometheus-speedtest-exporter](https://hub.docker.com/repository/docker/billimek/prometheus-speedtest-exporter) docker image is multi-arch supporting amd64, arm7, and arm64.

## Prometheus configuration

The script_exporter needs to be passed the script name as a parameter (script). It is advised to use a long `scrape_interval` to avoid excessive bandwidth use.

Example config:

```yaml
scrape_configs:
  - job_name: 'speedtest'
    metrics_path: /probe
    params:
      script: [speedtest]
    static_configs:
      - targets:
        - 127.0.0.1:9469
    scrape_interval: 60m
    scrape_timeout: 90s
  - job_name: 'script_exporter'
    metrics_path: /metrics
    static_configs:
      - targets:
        - 127.0.0.1:9469
```

## helm chart

If running in kubernetes, there is a helm chart leveraging this with a built-in `ServiceMonitor` for an autoconfigured solution: https://github.com/billimek/billimek-charts/tree/master/charts/speedtest-prometheus

## Grafana Dashboard

Included is an [example grafana dashboard](speedtest-exporter.json) as shown in the screenshot above.

## Inspired by

* https://github.com/h2xtreme/prometheus-speedtest-exporter
* https://github.com/ricoberger/script_exporter
* https://github.com/pschmitt/docker-ookla-speedtest-cli