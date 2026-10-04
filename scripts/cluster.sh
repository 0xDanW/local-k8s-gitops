#!/usr/bin/env bash
# Manage the single-node colima k8s cluster (k3s + docker).
# Usage: cluster.sh up|stop|delete|status
source "$(dirname "$0")/common.sh"
require colima kubectl

cmd="${1:-}"
case "$cmd" in
  up)
    log "starting colima profile '$COLIMA_PROFILE' (k8s, docker)"
    args=(start --profile "$COLIMA_PROFILE"
          --runtime docker --kubernetes
          --cpu "$COLIMA_CPU" --memory "$COLIMA_MEMORY" --disk "$COLIMA_DISK")
    [[ -n "$K8S_VERSION" ]] && args+=(--kubernetes-version "$K8S_VERSION")
    colima "${args[@]}"
    kc wait --for=condition=Ready node --all --timeout=180s
    kc get nodes -o wide
    ;;
  stop)
    # Tear down workloads first so the next `up` starts from a clean cluster.
    if kc get --raw /readyz >/dev/null 2>&1; then
      log "removing all workloads"
      list_workloads | while read -r n _; do "$ROOT_DIR/scripts/workload.sh" down "$n"; done
    else
      log "cluster not reachable; skipping workload teardown"
    fi
    colima stop --profile "$COLIMA_PROFILE"
    ;;
  delete)
    log "deleting colima profile '$COLIMA_PROFILE' (VM, cluster, images, volumes)"
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
