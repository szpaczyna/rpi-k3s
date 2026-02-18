#!/usr/bin/env bash
set -euo pipefail

SOPS_FILE="${SOPS_FILE:-../../secrets/media-exporter-secret.yaml}"
NAMESPACE="${NAMESPACE:-media}"

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require kubectl
require sops
require base64

pod_for_app() {
  local app="$1"
  kubectl -n "$NAMESPACE" get pod -l "app.kubernetes.io/name=${app}" -o name 2>/dev/null | head -n1 | sed 's#pod/##'
}

arr_apikey_from_config_xml() {
  local pod="$1"
  local container="$2"

  kubectl -n "$NAMESPACE" exec "$pod" -c "$container" -- sh -lc \
    'grep -oE "<ApiKey>[^<]+" /config/config.xml 2>/dev/null | head -n1 | sed -E "s#<ApiKey>##" | tr -d "\r\n"'
}

bazarr_apikey_from_config_yaml() {
  local pod="$1"

  # Extract auth.apikey block, then strip surrounding quotes if present.
  local raw
  raw="$(
    kubectl -n "$NAMESPACE" exec "$pod" -c bazarr -- sh -lc \
      "awk 'BEGIN{a=0} /^auth:/{a=1;next} a && /^[^ ]/{a=0} a && /^  apikey:/{sub(/^  apikey:[[:space:]]*/,\"\"); print; exit}' /config/config/config.yaml 2>/dev/null"
  )"

  # Remove any single/double quotes (Bazarr sometimes stores the value quoted)
  printf %s "$raw" | tr -d '"\047' | tr -d "\r\n"
}

set_sops_data_key_b64() {
  local key_name="$1"
  local value_b64="$2"

  sops --set "[\"data\"][\"${key_name}\"] \"${value_b64}\"" "$SOPS_FILE" >/dev/null
}

sync_arr() {
  local app="$1"
  local pod
  pod="$(pod_for_app "$app")"
  if [[ -z "$pod" ]]; then
    echo "[$app] pod not found; skipping" >&2
    return 0
  fi

  local apikey
  apikey="$(arr_apikey_from_config_xml "$pod" "$app" || true)"
  if [[ -z "$apikey" ]]; then
    echo "[$app] ApiKey not found in /config/config.xml; skipping" >&2
    return 0
  fi

  local upper
  upper="$(printf %s "$app" | tr '[:lower:]' '[:upper:]')"

  local key_name
  key_name="${upper}_APIKEY"

  local value_b64
  value_b64="$(printf %s "$apikey" | base64 | tr -d '\n')"

  set_sops_data_key_b64 "$key_name" "$value_b64"
  echo "[$app] updated ${key_name} in ${SOPS_FILE} (value not printed)"
}

sync_bazarr() {
  local app=bazarr
  local pod
  pod="$(pod_for_app "$app")"
  if [[ -z "$pod" ]]; then
    echo "[$app] pod not found; skipping" >&2
    return 0
  fi

  local apikey
  apikey="$(bazarr_apikey_from_config_yaml "$pod" || true)"
  if [[ -z "$apikey" ]]; then
    echo "[$app] auth.apikey not found in /config/config/config.yaml; skipping" >&2
    return 0
  fi

  if ! printf %s "$apikey" | grep -Eq '^[A-Za-z0-9]{20,32}$'; then
    echo "[$app] extracted apikey does not match Exportarr expected format (20-32 alnum); not updating" >&2
    return 1
  fi

  local value_b64
  value_b64="$(printf %s "$apikey" | base64 | tr -d '\n')"

  set_sops_data_key_b64 "BAZARR_APIKEY" "$value_b64"
  echo "[$app] updated BAZARR_APIKEY in ${SOPS_FILE} (value not printed)"
}

main() {
  echo "Syncing Exportarr API keys into ${SOPS_FILE} (namespace=${NAMESPACE})"

  sync_arr sonarr
  sync_arr radarr
  sync_arr lidarr
  sync_arr readarr
  sync_arr prowlarr
  sync_bazarr

  echo "Done. Apply to cluster with: ./deploy && kubectl -n ${NAMESPACE} rollout restart deploy/{sonarr,radarr,lidarr,readarr,prowlarr,bazarr}"
}

main "$@"
