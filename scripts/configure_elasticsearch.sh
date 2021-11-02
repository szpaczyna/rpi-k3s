#!/bin/bash

curlie - XPUT '10.1.0.11:9200/_template/auth' - H 'Content-Type: application/json' - d ' {
"index_patterns": ["auth-*"]
"mappings": {
  "properties": {
    "geoip": {
      "dynamic": true,
      "properties": {
        "ip": {
          "type": "ip"
        },
        "coordinates": {
          "type": "geo_point"
        },
        "latitude": {
          "type": "half_float"
        },
        "longitude": {
          "type": "half_float"
        }
      }
    }
  }
}
}
'

curlie - XPUT '10.1.0.11:9200/_template/default' - H 'Content-Type: application/json' - d ' {
"template": ["*"],
"index_patterns": ["*"],
"order": "-1",
"settings": {
  "number_of_shards": "2",
  "number_of_replicas": "0"
}
}
'
