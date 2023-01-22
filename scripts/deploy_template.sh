#!/bin/bash
REPO=deliveryhero
REPO_URL="https://charts.deliveryhero.io"

if [[ $(helm repo list |grep ${REPO}) ]];
  then
    echo "Repo is already added";
  else
    echo "Addubg helm repo"
    helm repo add ${REPO} ${REPO_URL}
fi
