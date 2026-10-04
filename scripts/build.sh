#!/usr/bin/env bash
# Render workloads to build/<name>/<Kind>.<metadata.name>.yaml and validate them.
# Usage: build.sh build [name]   # all workloads when name omitted
#        build.sh test           # kubeconform over build/
#        build.sh clean
source "$(dirname "$0")/common.sh"

BUILD_DIR="$ROOT_DIR/build"

build_one() {
  local name="$1" out="$BUILD_DIR/$1"
  workload_type "$name" >/dev/null
  rm -rf "$out" && mkdir -p "$out"
  log "rendering $name -> build/$name"
  # select(length > 0) stops yq writing a blank file when render emits nothing.
  render "$name" | (cd "$out" && yq 'select(length > 0)' --no-doc -s '.kind + "." + .metadata.name + ".yaml"')
}

cmd="${1:-}"
case "$cmd" in
  build)
    require yq
    if [[ -n "${2:-}" ]]; then
      build_one "$2"
    else
      list_workloads | while read -r n _; do build_one "$n"; done
    fi
    ;;
  test)
    require kubeconform
    [[ -d "$BUILD_DIR" ]] || die "nothing to test; run 'make build' first"
    kubeconform -strict -summary -ignore-missing-schemas -skip CustomResourceDefinition \
      -schema-location default \
      -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
      "$BUILD_DIR"
    ;;
  clean)
    rm -rf "$BUILD_DIR"
    ;;
  *)
    die "usage: $0 build [name] | test | clean"
    ;;
esac
