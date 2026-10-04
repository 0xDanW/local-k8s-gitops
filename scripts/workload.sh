#!/usr/bin/env bash
# Spin a workload up/down. All workloads share one namespace ($NAMESPACE).
# Usage: workload.sh up|down|diff|render <name>
#        workload.sh list
source "$(dirname "$0")/common.sh"
require kubectl

cmd="${1:-}"
name="${2:-}"

if [[ "$cmd" == "list" ]]; then
  list_workloads | column -t
  exit 0
fi

[[ -n "$name" ]] || die "usage: $0 up|down|diff|render <name> | list"
type="$(workload_type "$name")"

ensure_ns() {
  kc get namespace "$NAMESPACE" >/dev/null 2>&1 || kc create namespace "$NAMESPACE"
}

case "$cmd:$type" in
  render:*)
    render "$name"
    ;;
  up:kustomize)
    log "applying kustomize/$name -> ns/$NAMESPACE"
    ensure_ns
    render "$name" | kc apply -n "$NAMESPACE" -f -
    ;;
  up:chart)
    log "installing charts/$name -> ns/$NAMESPACE"
    ensure_ns
    chart_values_args "$name"
    hlm upgrade --install "$name" "$ROOT_DIR/charts/$name" -n "$NAMESPACE" \
      ${VALUES_ARGS[@]+"${VALUES_ARGS[@]}"}
    ;;
  down:kustomize)
    log "deleting kustomize/$name from ns/$NAMESPACE"
    render "$name" | kc delete -n "$NAMESPACE" --ignore-not-found -f -
    ;;
  down:chart)
    log "uninstalling charts/$name from ns/$NAMESPACE"
    hlm uninstall "$name" -n "$NAMESPACE" --ignore-not-found
    ;;
  diff:*)
    render "$name" | kc diff -n "$NAMESPACE" -f - || true
    ;;
  *)
    die "usage: $0 up|down|diff|render <name> | list"
    ;;
esac
