#!/bin/bash

## variables
GITEA_USERNAME=""
GITEA_TOKEN=""
GITEA_DOMAIN=""
GITEA_REPO_OWNER=""

## repositories
REPOS=(https://github.com/QNapi/qnapi-docker.git
  https://github.com/necrose99/gentoo-on-rpi-64bit.git
  https://github.com/linuxserver/docker-calibre.git
  https://github.com/szpaczyna/transmission-exporter.git
  https://github.com/ams0/rancher-home.git
  https://github.com/szpaczyna/elasticvue.git
  https://github.com/szpaczyna/nocodb.git
  https://github.com/szpaczyna/prospect-mail.git
  https://github.com/CometTools/LunaSea.git
  https://github.com/rs/curlie.git
  https://github.com/Sonarr/Sonarr.git
  https://github.com/Lidarr/Lidarr.git
  https://github.com/Radarr/Radarr.git
  https://github.com/Readarr/Readarr.git
  https://github.com/kovidgoyal/calibre.git
  https://github.com/sct/overseerr.git
  https://github.com/bastienwirtz/homer.git
  https://github.com/Jackett/Jackett.git
  https://github.com/Prowlarr/Prowlarr.git
  https://github.com/sharat87/prestige.git
  https://github.com/neovim/neovim.git
  https://github.com/szpaczyna/rpi-k3s.git
  https://github.com/angelnu/k8s-gitops.git
  https://github.com/httpie/httpie.git
  https://github.com/auricom/home-cluster.git
  https://github.com/onedr0p/home-cluster.git
  https://github.com/anthr76/infra.git
  )

for URL in ${REPOS[@]}; do
    REPO_NAME=$(echo $URL | sed -e 's|https://github.com/||g' -e 's|/|-|g'  -e 's|.git||g')
    echo "Importing repo from $URL to $REPO_NAME…"

    curlie -X POST "https://$GITEA_DOMAIN/api/v1/repos/migrate" -u $GITEA_USERNAME:$GITEA_TOKEN -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \
    \"clone_addr\": \"$URL\", \
    \"mirror\": true, \
    \"private\": false, \
    \"repo_name\": \"$REPO_NAME\", \
    \"repo_owner\": \"$GITEA_REPO_OWNER\", \
    \"service\": \"git\", \
    \"uid\": 0, \
    \"wiki\": true}"

done
