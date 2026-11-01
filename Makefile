SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

CLUSTER_DIR := cluster/helm

# Order matters for `make all`: networking/storage infra first, then
# cert-manager + traefik (Gateway API CRDs + the websecure listener every
# app's Certificate depends on), then everything else.
INFRA        := metallb longhorn
INGRESS      := cert-manager traefik-external traefik-internal
PLATFORM     := local-path-provisioner system-upgrade-controller renovate postgresql middlewares defaultbackend
MONITORING   := prometheus grafana loki speedtest x509-certificate-exporter unifipoller version-checker
APPS         := authelia bitwarden booklore gitea gentoo homepage media-stack pihole shpaq-org whoops

COMPONENTS := $(INFRA) $(INGRESS) $(PLATFORM) $(MONITORING) $(APPS)

.DEFAULT_GOAL := help

.PHONY: all $(COMPONENTS) helm-update enc yamllint jsonlint help

all: $(COMPONENTS) ## Deploy all components

$(COMPONENTS):
	cd $(CLUSTER_DIR)/$@ && ./deploy

helm-update: ## Update Helm repositories
	helm repo update

enc: ## Encrypt all *secret.yaml files with sops
	find . -name "*secret.yaml" | xargs -I {} sops -e -i {}

help: ## Show this help message
	@echo "Usage: make <target>"
	@echo ""
	@echo "Top-level targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'
	@echo ""
	@echo "Components (deploy a single component):"
	@for c in $(COMPONENTS); do printf "  %s\n" "$$c"; done
