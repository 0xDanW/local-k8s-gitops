SHELL := /bin/bash
.DEFAULT_GOAL := help

S := ./scripts
W ?=

.PHONY: help cluster-up cluster-stop cluster-delete status list up down diff render build test clean pull-chart up-all down-all

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-15s\033[0m %s\n",$$1,$$2}'

cluster-up: ## Start colima k8s cluster
	@$(S)/cluster.sh up

cluster-stop: ## Stop cluster (keeps state)
	@$(S)/cluster.sh stop

cluster-delete: ## Delete cluster and all state
	@$(S)/cluster.sh delete

status: ## Cluster status
	@$(S)/cluster.sh status

list: ## List workloads in repo
	@$(S)/workload.sh list

up: ## Deploy workload: make up W=<name>
	@$(S)/workload.sh up $(W)

down: ## Remove workload: make down W=<name>
	@$(S)/workload.sh down $(W)

diff: ## Diff workload vs cluster: make diff W=<name>
	@$(S)/workload.sh diff $(W)

render: ## Render manifests: make render W=<name>
	@$(S)/workload.sh render $(W)

build: ## Render to build/ (all, or W=<name>)
	@$(S)/build.sh build $(W)

test: build ## Build then validate with kubeconform
	@$(S)/build.sh test

clean: ## Remove build/
	@$(S)/build.sh clean

pull-chart: ## Vendor chart: make pull-chart W=<name> CHART=<ref> [VERSION=] [REPO=]
	@$(S)/pull-chart.sh $(W) $(CHART) "$(VERSION)" "$(REPO)"

up-all: ## Deploy every workload
	@$(S)/workload.sh list | while read -r n _; do $(S)/workload.sh up $$n; done

down-all: ## Remove every workload
	@$(S)/workload.sh list | while read -r n _; do $(S)/workload.sh down $$n; done
