#!/bin/bash
GRAFANA_HOST=grafana.shpaq.org

for i in $(curl -X GET --insecure -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" "https://${GRAFANA_HOST}/api/search?folderIds=0&query=&starred=false" | jq '.[].uri' | sed 's/"//g')
  do
    curl -X GET --insecure -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" "https://${GRAFANA_HOST}/api/dashboards/${i//\"}" | jq '.dashboard' > "${i//db\/}.json"
  done
