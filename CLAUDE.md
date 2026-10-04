# CLAUDE.md

Local GitOps repo: k8s workloads for a single-node colima cluster (k3s, docker runtime). See README.md for commands.

## Conventions
- `kustomize/<name>/` — `kustomization.yaml` with plain manifests and/or `helmCharts:` (public repo, pinned `version`). Rendered with `kustomize build --enable-helm`. No hardcoded `namespace:`; scripts deploy everything into the shared ns `$NAMESPACE` (default `default`).
- `charts/<name>/` — vendored chart (Chart.yaml at root) via `make pull-chart`; never hand-edit vendored templates, put overrides in `values-local.yaml`.
- Workload name = helm release; unique across both dirs. Resource names must not collide between workloads since they share a namespace.
- Automation lives in `scripts/` and is exposed via `Makefile`. Add new behavior there, not as ad-hoc commands.

## Adding / upgrading a workload
1. Public image or public chart → `kustomize/<name>/`. Chart that needs pinning/patching locally → `make pull-chart`.
2. Pin versions (image tag or chart `version`); bump them in place to upgrade.
3. `make test W=<name>` (render + kubeconform) must pass before `make up W=<name>`.

## Rules
- Always go through `kc`/`hlm` helpers (pinned to `$KUBE_CONTEXT`, default `colima`). Never run kubectl/helm without an explicit context.
- Never commit secrets; use placeholder values or local-only files ignored by git.
- Don't start the cluster or deploy workloads unless asked.
