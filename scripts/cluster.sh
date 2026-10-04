#!/usr/bin/env bash
# Manage the single-node colima k8s cluster (k3s + containerd).
# Usage: cluster.sh up|stop|delete|status
source "$(dirname "$0")/common.sh"
require colima kubectl

cmd="${1:-}"
case "$cmd" in
  up)
    log "starting colima profile '$COLIMA_PROFILE' (k8s, containerd)"
    args=(start --profile "$COLIMA_PROFILE"
          --runtime containerd --kubernetes
          --cpu "$COLIMA_CPU" --memory "$COLIMA_MEMORY" --disk "$COLIMA_DISK")
    [[ -n "$K8S_VERSION" ]] && args+=(--kubernetes-version "$K8S_VERSION")
    colima "${args[@]}"
    kc wait --for=condition=Ready node --all --timeout=180s
    kc get nodes -o wide
    ;;
  stop)
    colima stop --profile "$COLIMA_PROFILE"
    ;;
  delete)
    colima delete --profile "$COLIMA_PROFILE" --force
    ;;
  status)
    colima status --profile "$COLIMA_PROFILE" || true
    kc get nodes -o wide 2>/dev/null || true
    ;;
  *)
    die "usage: $0 up|stop|delete|status"
    ;;
esac
