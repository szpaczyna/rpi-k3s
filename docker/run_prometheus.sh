#!/bin/bash

docker run \
    -d -p 9090:9090 \
    --name=prometheus \
    -v /home/shpaq/docker/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
