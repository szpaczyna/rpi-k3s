#!/bin/bash
GRAFANA_HOST=https://grafana.shpaq.org/api
TOKEN=$1

out=$(curl -s -H "Authorization: Bearer ${TOKEN}" -X GET ${GRAFANA_HOST}/search?query=&starred=false)
  for uid in $(echo $out | jq -r '.[] | .uid'); do
    title=$(curl -s -H "Authorization: Bearer ${TOKEN}" ${GRAFANA_HOST}/dashboards/uid/$uid | jq '.meta.slug' | sed -e 's/\"//g')
    curl -s -H "Authorization: Bearer ${TOKEN}" ${GRAFANA_HOST}/dashboards/uid/$uid | jq > $title.json
    echo "Dashboard $title exported"
  done
