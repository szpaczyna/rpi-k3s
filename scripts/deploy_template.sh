#!/bin/bash
# Template for <component>/deploy. Copy it next to the chart and replace the
# placeholders.
#
# Contract:
# - VERSION holds the exact chart version for upstream charts and stays empty
#   for local charts.
# - The Helm repo is added only when it is not configured yet. Deploys do not
#   refresh repo indexes; run `make helm-update` after changing a pin.
# - Secrets the release mounts are applied before the Helm upgrade so the
#   first reconcile can find them.
set -euo pipefail

NAMESPACE="apps"
RELEASE_NAME="example"
CHART="."

# Upstream charts only.
VERSION=""
REPO_NAME=""
REPO_URL=""

# jq is required for the repo lookup.
if [[ -n "${REPO_NAME}" ]]; then
  if ! helm repo list -o json | jq -e --arg name "${REPO_NAME}" 'any(.[]?; .name == $name)' >/dev/null; then
    helm repo add "${REPO_NAME}" "${REPO_URL}"
  fi
fi

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# Apply secrets and config the release mounts before Helm runs.
# kubectl apply -f <(sops -d ./secret.enc.yaml) -n "${NAMESPACE}"

HELM_ARGS=(upgrade --install "${RELEASE_NAME}" "${CHART}"
  --namespace "${NAMESPACE}"
  --create-namespace)

[[ -f values.yaml ]] && HELM_ARGS+=(--values values.yaml)
# Encrypted values: HELM_ARGS+=(--values <(sops -d ./values.enc.yaml))
[[ -n "${VERSION}" ]] && HELM_ARGS+=(--version "${VERSION}")

helm "${HELM_ARGS[@]}"

# Apply resources Helm does not own.
# kubectl apply -f extra.yaml -n "${NAMESPACE}"
