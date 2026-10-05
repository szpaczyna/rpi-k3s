SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

CLUSTER_DIR := cluster/helm

# Order matters for `make all`: networking/storage infra first, then
# cert-manager + traefik (Gateway API CRDs + the websecure listener every
# app's Certificate depends on), then everything else.
INFRA        := metallb longhorn
INGRESS      := cert-manager traefik
PLATFORM     := local-path-provisioner system-upgrade-controller renovate postgresql middlewares defaultbackend
MONITORING   := prometheus grafana loki speedtest x509-certificate-exporter unifipoller version-checker
APPS         := authelia bitwarden booklore gitea media-stack pihole shpaq-org whoops

COMPONENTS := $(INFRA) $(INGRESS) $(PLATFORM) $(MONITORING) $(APPS)

.PHONY: all $(COMPONENTS) enc yamllint jsonlint

all: $(COMPONENTS)

$(COMPONENTS):
	cd $(CLUSTER_DIR)/$@ && ./deploy

enc:
	find . -name "*secret.yaml" | xargs -I {} sops -e -i {}
yamllint:
	yamllint -c .github/yamllint.config.yaml yaml
jsonlint:
	jsonlint json/*/*.json
