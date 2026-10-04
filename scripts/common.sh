#!/usr/bin/env bash
# Shared settings. Every kubectl/helm call is pinned to the colima context
# so nothing here can touch another cluster in your kubeconfig.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

COLIMA_PROFILE="${COLIMA_PROFILE:-default}"
COLIMA_CPU="${COLIMA_CPU:-4}"
COLIMA_MEMORY="${COLIMA_MEMORY:-8}"
COLIMA_DISK="${COLIMA_DISK:-60}"
K8S_VERSION="${K8S_VERSION:-}"
NAMESPACE="${NAMESPACE:-default}"

if [[ "$COLIMA_PROFILE" == "default" ]]; then
  KUBE_CONTEXT="${KUBE_CONTEXT:-colima}"
else
  KUBE_CONTEXT="${KUBE_CONTEXT:-colima-$COLIMA_PROFILE}"
fi

kc()   { kubectl --context "$KUBE_CONTEXT" "$@"; }
hlm()  { helm --kube-context "$KUBE_CONTEXT" "$@"; }
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 || die "missing dependency: $bin"
  done
}

# Prints "kustomize" or "chart" for a workload name, or fails.
workload_type() {
  local name="$1"
  if [[ -f "$ROOT_DIR/kustomize/$name/kustomization.yaml" ]]; then
    echo kustomize
  elif [[ -f "$ROOT_DIR/charts/$name/Chart.yaml" ]]; then
    echo chart
  else
    die "workload '$name' not found in kustomize/ or charts/"
  fi
}

# Sets VALUES_ARGS to "-f charts/<name>/values-local.yaml" when present.
chart_values_args() {
  local values="$ROOT_DIR/charts/$1/values-local.yaml"
  VALUES_ARGS=()
  [[ -f "$values" ]] && VALUES_ARGS=(-f "$values")
  return 0
}

# Prints the fully rendered manifests for a workload to stdout.
# kustomize dirs may use `helmCharts:` (public charts), hence --enable-helm.
render() {
  local name="$1" type
  type="$(workload_type "$name")"
  case "$type" in
    kustomize)
      require kustomize helm
      kustomize build --enable-helm --load-restrictor=LoadRestrictionsNone "$ROOT_DIR/kustomize/$name"
      ;;
    chart)
      require helm
      chart_values_args "$name"
      helm template "$name" "$ROOT_DIR/charts/$name" -n "$NAMESPACE"${VALUES_ARGS[@]+"${VALUES_ARGS[@]}"}
      ;;
  esac
}

list_workloads() {
  local d
  for d in "$ROOT_DIR"/kustomize/*/kustomization.yaml; do
    [[ -e "$d" ]] && echo "$(basename "$(dirname "$d")") kustomize"
  done
  for d in "$ROOT_DIR"/charts/*/Chart.yaml; do
    [[ -e "$d" ]] && echo "$(basename "$(dirname "$d")") chart"
  done
  return 0
}
