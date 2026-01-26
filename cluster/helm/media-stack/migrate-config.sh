#!/bin/bash
set -euo pipefail

NAMESPACE="media"
OLD_PVC="media"
APPS=(radarr sonarr lidarr prowlarr readarr bazarr transmission)
RSYNC_FLAGS="-Paz"  # progress, archive, compress
FORCE=0
NO_SCALE=0

usage() { cat <<EOF
Usage: $0 [--force] [--no-scale] [--no-rsync]

Options:
  --force        Overwrite existing data in per-app PVCs (clear destination before copy)
  --no-scale     Do not scale deployments down/up
  --no-rsync     Skip rsync; use tar streaming copy method
  -h, --help     Show this help
EOF
}

USE_RSYNC=1
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --no-scale) NO_SCALE=1 ;;
    --no-rsync) USE_RSYNC=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage; exit 1 ;;
  esac
done

[[ $FORCE -eq 1 ]] && echo "[INFO] Force mode enabled"
[[ $NO_SCALE -eq 1 ]] && echo "[INFO] No-scale mode enabled"
[[ $USE_RSYNC -eq 0 ]] && echo "[INFO] Using tar fallback copy method (rsync disabled)"

check_cluster() {
  command -v kubectl >/dev/null || { echo "kubectl missing"; exit 1; }
  kubectl get ns "$NAMESPACE" >/dev/null || { echo "Namespace $NAMESPACE not found"; exit 1; }
  kubectl get pvc "$OLD_PVC" -n "$NAMESPACE" >/dev/null || { echo "Source PVC '$OLD_PVC' missing"; exit 1; }
  for app in "${APPS[@]}"; do kubectl get pvc "$app" -n "$NAMESPACE" >/dev/null || { echo "Target PVC '$app' missing"; exit 1; }; done
  echo "✓ PVCs present"
}

scale_down() {
  [[ $NO_SCALE -eq 1 ]] && { echo "Skipping scale down"; return; }
  echo "Scaling down deployments..."
  kubectl scale deployment -n "$NAMESPACE" "${APPS[@]}" --replicas=0 || true
  kubectl wait --for=delete pod -n "$NAMESPACE" \
    -l 'app.kubernetes.io/name in (radarr,sonarr,lidarr,prowlarr,readarr,bazarr,transmission)' \
    --timeout=180s || true
  echo "✓ Deployments scaled down"
}

create_migration_pod() {
  echo "Creating migration pod..."
  local image="instrumentisto/rsync-ssh:latest"
  
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: migration-pod
  namespace: ${NAMESPACE}
spec:
  restartPolicy: Never
  containers:
  - name: migrator
    image: ${image}
    command:
    - /bin/sh
    - -c
    - which rsync || echo 'rsync missing'; sleep 7200
    securityContext:
      runAsUser: 0
      runAsGroup: 0
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
    volumeMounts:
    - name: old-config
      mountPath: /old-config
    - name: new-radarr
      mountPath: /new-config/radarr
    - name: new-sonarr
      mountPath: /new-config/sonarr
    - name: new-lidarr
      mountPath: /new-config/lidarr
    - name: new-prowlarr
      mountPath: /new-config/prowlarr
    - name: new-readarr
      mountPath: /new-config/readarr
    - name: new-bazarr
      mountPath: /new-config/bazarr
    - name: new-transmission
      mountPath: /new-config/transmission
  volumes:
  - name: old-config
    persistentVolumeClaim:
      claimName: ${OLD_PVC}
  - name: new-radarr
    persistentVolumeClaim:
      claimName: radarr
  - name: new-sonarr
    persistentVolumeClaim:
      claimName: sonarr
  - name: new-lidarr
    persistentVolumeClaim:
      claimName: lidarr
  - name: new-prowlarr
    persistentVolumeClaim:
      claimName: prowlarr
  - name: new-readarr
    persistentVolumeClaim:
      claimName: readarr
  - name: new-bazarr
    persistentVolumeClaim:
      claimName: bazarr
  - name: new-transmission
    persistentVolumeClaim:
      claimName: transmission
EOF
  kubectl wait --for=condition=Ready pod/migration-pod -n "$NAMESPACE" --timeout=120s
  echo "✓ Migration pod ready"
}

copy_with_rsync() {
  local src="$1" dst="$2"
  kubectl exec -n "$NAMESPACE" migration-pod -- rsync $RSYNC_FLAGS "$src/" "$dst/"
}

copy_with_tar() {
  local src="$1" dst="$2"
  kubectl exec -n "$NAMESPACE" migration-pod -- sh -c "cd '$src' && tar cf - . | (cd '$dst' && tar xpf -)"
}

rsync_app() {
  local app="$1" src="/old-config/config/${app}" dst="/new-config/${app}"
  echo "-- $app --"
  if ! kubectl exec -n "$NAMESPACE" migration-pod -- test -d "$src"; then echo "  Source missing, skipping"; return; fi
  kubectl exec -n "$NAMESPACE" migration-pod -- sh -c "mkdir -p '$dst'"

  if kubectl exec -n "$NAMESPACE" migration-pod -- sh -c "[ \"\$(ls -A '$dst' 2>/dev/null)\" ]"; then
    if [[ $FORCE -eq 1 ]]; then
      echo "  Destination not empty; FORCE -> clearing"
      kubectl exec -n "$NAMESPACE" migration-pod -- sh -c "rm -rf '$dst'/*"
    else
      echo "  Destination not empty; skip (use --force)"; return
    fi
  fi

  if ! kubectl exec -n "$NAMESPACE" migration-pod -- sh -c "[ \"\$(ls -A '$src' 2>/dev/null)\" ]"; then echo "  Source empty; nothing to copy"; return; fi

  if [[ $USE_RSYNC -eq 1 ]]; then
    # double-check rsync availability
    if kubectl exec -n "$NAMESPACE" migration-pod -- which rsync >/dev/null 2>&1; then
      echo "  Copying with rsync"
      copy_with_rsync "$src" "$dst"
    else
      echo "  rsync not found; falling back to tar copy"
      copy_with_tar "$src" "$dst"
    fi
  else
    echo "  Copying with tar (rsync disabled)"
    copy_with_tar "$src" "$dst"
  fi

  kubectl exec -n "$NAMESPACE" migration-pod -- chown -R 568:568 "$dst"

  local src_files dst_files src_bytes dst_bytes
  src_files=$(kubectl exec -n "$NAMESPACE" migration-pod -- sh -c "find '$src' -type f | wc -l")
  dst_files=$(kubectl exec -n "$NAMESPACE" migration-pod -- sh -c "find '$dst' -type f | wc -l")
  src_bytes=$(kubectl exec -n "$NAMESPACE" migration-pod -- du -sb "$src" | cut -f1)
  dst_bytes=$(kubectl exec -n "$NAMESPACE" migration-pod -- du -sb "$dst" | cut -f1)
  echo "  Files: $src_files -> $dst_files"
  echo "  Bytes: $src_bytes -> $dst_bytes"
  if [ "$src_files" -eq "$dst_files" ] && [ "$src_bytes" -eq "$dst_bytes" ]; then echo "  ✓ Verified"; else echo "  ⚠ Mismatch"; fi
}

migrate_all() { echo "Starting migration..."; for app in "${APPS[@]}"; do rsync_app "$app"; done; echo "✓ Migration phase complete"; }

list_summary() { echo "Summary counts:"; for app in "${APPS[@]}"; do kubectl exec -n "$NAMESPACE" migration-pod -- sh -c "echo -n '$app: '; ls -A /new-config/$app 2>/dev/null | wc -l" || true; done; }

cleanup() { echo "Cleaning up migration pod..."; kubectl delete pod migration-pod -n "$NAMESPACE" --ignore-not-found; echo "✓ Cleanup done"; }

scale_up() {
  [[ $NO_SCALE -eq 1 ]] && { echo "Skipping scale up"; return; }
  echo "Scaling deployments up..."
  kubectl scale deployment -n "$NAMESPACE" "${APPS[@]}" --replicas=1
  for app in "${APPS[@]}"; do kubectl rollout status -n "$NAMESPACE" deployment/"$app" --timeout=120s || true; done
  echo "✓ Deployments restored"
}

main() {
  check_cluster
  echo "This will STOP all apps unless --no-scale. Continue? (y/N): "
  read -r reply
  [[ $reply =~ ^[Yy]$ ]] || { echo "Cancelled"; exit 0; }
  trap cleanup EXIT
  scale_down
  create_migration_pod
  migrate_all
  list_summary
  scale_up
  echo "=== Done. Validate each app before removing old data ==="
}

main "$@"
