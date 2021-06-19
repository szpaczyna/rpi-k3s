.PHONY: enc yamllint jsonlint
enc:
	find . -name "*secret.yaml" | xargs -I {} sops -e -i {}
yamllint:
	yamllint -c .github/yamllint.config.yaml yaml
jsonlint:
	jsonlint json/*/*.json
