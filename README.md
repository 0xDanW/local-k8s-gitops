# local-k8s-gitops

Kubernetes workloads declared in git, spun up/down on a local single-node colima cluster (k3s + containerd).

## Dependencies

```sh
brew install colima kubectl kustomize helm yq kubeconform
```

`kustomize` (standalone) is needed for `helmCharts:` support via `--enable-helm`. `yq` and `kubeconform` are only used by `make build` / `make test`. No Docker Desktop needed.

## Cluster setup

```sh
make cluster-up      # colima start --runtime containerd --kubernetes
make status
```

Defaults: 4 CPU / 8 GiB RAM / 60 GiB disk, profile `default`, kube context `colima`. Override via env:

```sh
COLIMA_CPU=6 COLIMA_MEMORY=12 K8S_VERSION=v1.31.4+k3s1 make cluster-up
COLIMA_PROFILE=dev make cluster-up   # context becomes colima-dev
```

All scripts pin `--context` to the colima context, so other clusters in your kubeconfig are never touched.

`make cluster-stop` pauses the VM; `make cluster-delete` wipes it.

## Usage

```sh
make list                          # workloads found in repo
make up   W=<name>                 # deploy into the shared namespace
make down W=<name>                 # remove workload (namespace kept)
make diff W=<name>                 # diff repo vs cluster
make render W=<name>               # print rendered manifests
make build [W=<name>]              # render to build/<name>/<Kind>.<name>.yaml
make test                          # build + kubeconform validation
make up-all / make down-all

# vendor a chart into charts/<name>
make pull-chart W=redis CHART=oci://registry-1.docker.io/bitnamicharts/redis VERSION=20.1.0
make pull-chart W=grafana CHART=grafana VERSION=8.5.0 REPO=https://grafana.github.io/helm-charts
```

## Layout

```
kustomize/<workload>/   kustomization.yaml: plain manifests and/or helmCharts: from public repos
charts/<workload>/      vendored (pulled) helm chart; overrides in values-local.yaml
scripts/                cluster.sh, workload.sh, build.sh, pull-chart.sh, common.sh
build/                  rendered output (gitignored)
Makefile                entrypoint
```

All workloads deploy into the `default` namespace (override with `NAMESPACE=...`). A workload name must be unique across `kustomize/` and `charts/`; for charts it is also the helm release name.
