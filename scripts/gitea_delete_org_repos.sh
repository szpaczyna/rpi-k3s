#!/usr/bin/env bash
set -euo pipefail

# Delete all repositories under a Gitea organization using the REST API.
# Default is DRY-RUN; set DRY_RUN=0 and CONFIRM=1 to actually delete.
# Requirements: curl, jq
#
# Env vars:
#   BASE_URL   - Gitea API base, e.g. https://gitea.shpaq.org/api/v1
#   ORG        - Organization name to target (default: branch)
#   GITEA_TOKEN- Personal access token with repo admin/delete permission
#   DRY_RUN    - 1 to preview, 0 to delete (default: 1)
#   CONFIRM    - 1 required to proceed when DRY_RUN=0 (safety latch)
#   EXCLUDE_REGEX - Optional regex to skip matching repo names
#   LIMIT      - Page size (default: 50)

BASE_URL=${BASE_URL:-https://gitea.shpaq.org/api/v1}
ORG=${ORG:-}
TOKEN=${GITEA_TOKEN:-}
DRY_RUN=${DRY_RUN:-1}
CONFIRM=${CONFIRM:-0}
EXCLUDE_REGEX=${EXCLUDE_REGEX:-}
LIMIT=${LIMIT:-50}

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }; }
need curl
need jq

if [ -z "$TOKEN" ]; then
  echo "Set GITEA_TOKEN with permissions to delete repos." >&2
  exit 1
fi

api() {
  local url="$1"
  shift || true
  curl -sS -H "Authorization: token $TOKEN" "$url" "$@"
}

delete_repo() {
  local owner="$1" repo="$2"
  if [ "$DRY_RUN" = "1" ]; then
    echo "DRY: Would delete $owner/$repo"
  else
    if [ "$CONFIRM" != "1" ]; then
      echo "Refusing to delete without CONFIRM=1" >&2
      exit 1
    fi
    # Use -sS -o /dev/null -w to show status; consider non-2xx as failure
    local status
    status=$(curl -sS -o /dev/null -w '%{http_code}' -H "Authorization: token $TOKEN" -X DELETE "${BASE_URL}/repos/${owner}/${repo}")
    if [ "$status" -ge 200 ] && [ "$status" -lt 300 ]; then
      echo "Deleted $owner/$repo (HTTP $status)"
    else
      echo "Failed to delete $owner/$repo (HTTP $status)" >&2
    fi
  fi
}

echo "Listing repos in org '${ORG}' from ${BASE_URL}"
page=1
total=0
while :; do
  repos_json=$(api "${BASE_URL}/orgs/${ORG}/repos?limit=${LIMIT}&page=${page}")
  count=$(echo "$repos_json" | jq 'length')
  [ "$count" -eq 0 ] && break
  names=$(echo "$repos_json" | jq -r '.[].name')
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    if [ -n "$EXCLUDE_REGEX" ] && echo "$name" | grep -Eq "$EXCLUDE_REGEX"; then
      echo "Skip (exclude): $ORG/$name"
      continue
    fi
    delete_repo "$ORG" "$name"
    total=$((total+1))
  done <<< "$names"
  page=$((page+1))
done

echo "Processed $total repos in org '$ORG'."
if [ "$DRY_RUN" = "1" ]; then
  echo "Dry-run complete. Set DRY_RUN=0 CONFIRM=1 to perform deletion."
fi
