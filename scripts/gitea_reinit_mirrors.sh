#!/usr/bin/env bash
set -euo pipefail

# Reinitialize missing Gitea mirror repositories on disk based on Postgres DB entries.
# Usage:
#   DRY_RUN=1 ./gitea_reinit_mirrors.sh   # show actions only
#   ./gitea_reinit_mirrors.sh             # perform actions
#
# Environment (defaults suit Gitea Helm chart):
#   DATA_DIR=/data
#   APP_INI=$DATA_DIR/gitea/conf/app.ini
#   REPO_ROOT=$DATA_DIR/git/repositories
#
# Intended to run inside the gitea pod (e.g., gitea-0).

DRY_RUN=${DRY_RUN:-0}
USE_PGPASS=${USE_PGPASS:-0}
DATA_DIR=${DATA_DIR:-/data}
APP_INI=${APP_INI:-$DATA_DIR/gitea/conf/app.ini}
REPO_ROOT=${REPO_ROOT:-$DATA_DIR/git/repositories}

log() { printf '%s\n' "$*"; }
run() { if [ "$DRY_RUN" = "1" ]; then log "DRY: $*"; else eval "$*"; fi; }
need() { command -v "$1" >/dev/null 2>&1 || { log "Missing required command: $1"; exit 1; }; }

need git
need psql

if [ ! -f "$APP_INI" ]; then
  log "Cannot find app.ini at $APP_INI. Set APP_INI or ensure you're in the gitea pod."
  exit 1
fi

# Prefer environment variables injected by Helm chart; fall back to parsing app.ini with grep/sed
# Env names follow Gitea convention: GITEA__database__HOST, NAME, USER, PASSWD
DB_HOST="${GITEA__database__HOST:-}"
DB_NAME="${GITEA__database__NAME:-}"
DB_USER="${GITEA__database__USER:-}"
DB_PASS="${GITEA__database__PASSWD:-}"

if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
  # Fallback to app.ini
  if [ -f "$APP_INI" ]; then
    DB_HOST="${DB_HOST:-$(grep -A20 '^\[database\]' "$APP_INI" | grep -E '^HOST[[:space:]]*=' | sed 's/.*=[[:space:]]*//') }"
    DB_NAME="${DB_NAME:-$(grep -A20 '^\[database\]' "$APP_INI" | grep -E '^NAME[[:space:]]*=' | sed 's/.*=[[:space:]]*//') }"
    DB_USER="${DB_USER:-$(grep -A20 '^\[database\]' "$APP_INI" | grep -E '^USER[[:space:]]*=' | sed 's/.*=[[:space:]]*//') }"
    DB_PASS="${DB_PASS:-$(grep -A20 '^\[database\]' "$APP_INI" | grep -E '^PASSWD[[:space:]]*=' | sed 's/.*=[[:space:]]*//') }"
  fi
fi

# Trim whitespace and CR from values to avoid auth issues (e.g., 'gitea ')
DB_HOST="$(echo -n "$DB_HOST" | tr -d '\r' | xargs)"
DB_NAME="$(echo -n "$DB_NAME" | tr -d '\r' | xargs)"
DB_USER="$(echo -n "$DB_USER" | tr -d '\r' | xargs)"
DB_PASS="$(echo -n "$DB_PASS" | tr -d '\r' | xargs)"

if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
  log "Failed to read database settings from $APP_INI"
  exit 1
fi

HOST_ONLY="${DB_HOST%%:*}"
PORT_PART="${DB_HOST#*:}"
if [ "$HOST_ONLY" = "$DB_HOST" ]; then
  DB_PORT=5432
else
  DB_PORT="$PORT_PART"
fi

# Prefer pgpass if requested; otherwise use PGPASSWORD
if [ "$USE_PGPASS" = "1" ]; then
  # Optional: user can set PGPASSFILE; otherwise default ~/.pgpass is used by psql
  if [ -n "${PGPASSFILE:-}" ]; then
    export PGPASSFILE
  fi
else
  export PGPASSWORD="$DB_PASS"
fi

SQL='SELECT r.id, u.name AS owner_name, r.name AS repo_name, m.remote_address
     FROM mirror m
     JOIN repository r ON r.id = m.repo_id
     JOIN "user" u ON u.id = r.owner_id;'

log "Querying Postgres for mirror entries…"
RESULTS=$(psql -h "$HOST_ONLY" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -At -F $'\t' -c "$SQL" || true)

if [ -z "$RESULTS" ]; then
  log "No mirror rows returned. Nothing to do."
  exit 0
fi

IFS=$'\n' read -r -d '' -a ROWS <<<"${RESULTS}" || true
log "Found ${#ROWS[@]} mirror entries. Processing…"

# Ensure root directory exists
run "mkdir -p '$REPO_ROOT'"

for row in "${ROWS[@]}"; do
  # Columns: repo_id\towner_name\trepo_name\tremote_address
  IFS=$'\t' read -r repo_id owner_name repo_name remote_address <<<"$row"
  repo_dir="$REPO_ROOT/$owner_name/$repo_name.git"

  log "Repo ID $repo_id → $owner_name/$repo_name.git ← $remote_address"

  # Create owner directory
  run "mkdir -p '$REPO_ROOT/$owner_name'"

  # Initialize bare repo if missing
  if [ ! -d "$repo_dir" ]; then
    run "git init --bare '$repo_dir'"
  fi

  # Ensure origin remote exists and is configured for mirror
  if ! git --git-dir "$repo_dir" remote get-url origin >/dev/null 2>&1; then
    run "git --git-dir '$repo_dir' remote add origin '$remote_address'"
  fi
  run "git --git-dir '$repo_dir' config remote.origin.fetch '+refs/*:refs/*'"
  run "git --git-dir '$repo_dir' config remote.origin.mirror true"

  # Prime repo by fetching (non-fatal if credentials or network fail)
  run "git --git-dir '$repo_dir' remote update origin --prune || true"

  # Best-effort ownership fix (if git user exists)
  if id git >/dev/null 2>&1; then
    run "chown -R git:git '$repo_dir'"
  fi

  log "Prepared $repo_dir"
  log "---"

done

# Regenerate hooks so Gitea can manage repo lifecycle correctly
if command -v gitea >/dev/null 2>&1; then
  log "Regenerating Gitea hooks…"
  run "gitea admin regenerate hooks --config '$APP_INI'"
  # Optional health check
  run "gitea doctor --run check-repo-health --config '$APP_INI' || true"
fi

log "Done. If DRY_RUN=1, re-run without DRY_RUN to apply changes."
