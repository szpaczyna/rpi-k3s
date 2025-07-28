#!/bin/bash

REPO=deliveryhero
REPO_URL="https://charts.deliveryhero.io"
APP=node-problem-detector
NS=monitoring

if [[ $(helm repo list |grep ${REPO}) ]];
  then
    echo "Repo is already added";
  else
    echo "Addubg helm repo"
    helm repo add ${REPO} ${REPO_URL}
fi

helm upgrade --install --create-namespace -n "${NS}" "${APP}" "${REPO}"/"${APP}" -f ./values.yaml
