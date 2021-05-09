.PHONY: enc yamllint
enc:
	find . -name "*secret.yaml" | xargs -I {} sops -e -i {}
yamllint:
	yamllint -c .github/yamllint.config.yaml yaml
