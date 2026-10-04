#!/usr/bin/env bash
# Vendor a helm chart into charts/<name> so it is pinned in git.
# Usage: pull-chart.sh <name> <chart-ref> [version] [repo-url]
#   chart-ref: "oci://registry/path/chart" or "<chart>" with repo-url
# Examples:
#   pull-chart.sh redis oci://registry-1.docker.io/bitnamicharts/redis 20.1.0
#   pull-chart.sh grafana grafana 8.5.0 https://grafana.github.io/helm-charts
source "$(dirname "$0")/common.sh"
require helm

name="${1:-}"; ref="${2:-}"; version="${3:-}"; repo="${4:-}"
[[ -n "$name" && -n "$ref" ]] || die "usage: $0 <name> <chart-ref> [version] [repo-url]"

dest="$ROOT_DIR/charts/$name"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

args=(pull "$ref" --untar --untardir "$tmp")
[[ -n "$version" ]] && args+=(--version "$version")
[[ -n "$repo" ]] && args+=(--repo "$repo")
helm "${args[@]}"

src="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[[ -f "$src/Chart.yaml" ]] || die "pulled chart has no Chart.yaml"

# Keep local overrides across re-pulls.
if [[ -f "$dest/values-local.yaml" ]]; then
  cp "$dest/values-local.yaml" "$src/values-local.yaml"
fi

rm -rf "$dest"
mv "$src" "$dest"
[[ -f "$dest/values-local.yaml" ]] || printf '# Local overrides for %s\n' "$name" > "$dest/values-local.yaml"

log "vendored $ref${version:+@$version} -> charts/$name"
