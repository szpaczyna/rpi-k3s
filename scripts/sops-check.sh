#!/bin/sh
# Pre-commit hook: fail if any `*.enc.*` file is not SOPS-encrypted.
#
# Covers all sops output flavours present in this repo:
#   - YAML with a top-level `sops:` key (incl. multi-document files,
#     e.g. cluster/helm/authelia/secrets.enc.yaml)
#   - JSON envelopes `{"data": ..., "sops": ...}` produced by sops for
#     raw text files (databases.enc.sql, scripts/network/*.enc.sh)
set -eu

fail=0
for f in "$@"; do
    if ! grep -qE '^sops:|^[[:space:]]*"?sops"?[[:space:]]*:|ENC\[AES256_GCM' "$f"; then
        echo "!! ERROR: file is not SOPS-encrypted: $f" >&2
        fail=1
    fi
done

test "$fail" -eq 0
