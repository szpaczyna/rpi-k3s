This repository is infrastructure-as-code for a Raspberry Pi k3s homelab. Treat it as a Kubernetes, Helm, YAML, and shell repository first.

## Scope and priorities
- Prefer the smallest possible change that satisfies the request.
- Follow the structure and conventions already used in the target directory.
- Do not introduce new tooling, frameworks, directory layouts, or naming schemes unless explicitly requested.
- Do not refactor unrelated files while making localized infrastructure changes.

## Repository layout
- `cluster/apps`: raw Kubernetes application manifests.
- `cluster/core`: core cluster resources and kustomizations.
- `cluster/helm`: local Helm charts and chart-specific resources.
- `cluster/secrets`: sensitive or encrypted secret material.
- `scripts`: shell utilities and cluster automation.
- `.github/workflows/lint-all.yml`: primary CI validation workflow.

## YAML and manifest rules
- Preserve existing YAML style, ordering, and indentation. Use 2 spaces.
- Avoid formatting churn in unrelated keys or files.
- Prefer consistency with neighboring manifests over generic Kubernetes style advice.
- Do not add labels, annotations, probes, affinities, security settings, or resource limits unless required by the task or already established nearby.
- Do not remove existing fields unless the change requires it.
- Keep `kustomization.yaml` resources ordered consistently with the surrounding file.

## Helm rules
- Keep chart structure unchanged unless the task explicitly requires chart restructuring.
- Preserve current values names, helper names, and template layout.
- Prefer simple templates over complex conditionals or indirection.
- Do not rename chart values or move settings between `values.yaml`, `values-public.yaml`, and templates unless explicitly requested.
- Some charts intentionally do not have a standard `values.yaml`; do not add one just to satisfy tooling unless the task requires it.
- When changing a chart, prefer patterns already used in that chart over patterns from other charts.

## Secrets rules
- Never expose, decrypt, or rewrite secrets in plaintext.
- Treat anything under `cluster/secrets` and any file matching `*secret.yaml` as sensitive.
- Preserve existing secret-management workflows and file boundaries.
- Do not copy secret values into public values files, templates, README files, comments, or examples.
- If a change depends on secret content that is not available, state the limitation instead of inventing values.

## Shell rules
- Keep shell changes minimal and compatible with the existing script style.
- Prefer portable shell patterns unless a script already relies on bash-specific behavior.
- Keep quoting explicit and avoid risky command substitutions or broad globbing changes.
- Do not rewrite shell scripts into another language.

## CI and validation rules
- Treat `.github/workflows/lint-all.yml` as the primary source of truth for validation behavior.
- Keep changes compatible with existing checks: yamllint, shellcheck, kubeconform, kube-linter, and chart testing.
- Do not change CI workflows or linter configs unless the task is specifically about CI or linting.
- Respect current repository tradeoffs: some kube-linter findings are intentionally excluded and should not be “fixed” unless requested.
- Respect existing yamllint ignores and conventions instead of trying to normalize all YAML in the repo.

## Commands to prefer
- Prefer existing repo commands before inventing new ones:
  - `npm test`
  - `npm run yamllint`
  - `npm run shellint`
  - `npm run jsonlint`
  - `make yamllint`
  - `make jsonlint`
- For Helm changes, use targeted validation such as `helm lint <chart-dir>` and `helm template <release-name> <chart-dir>` when appropriate.

## What to avoid
- Do not mass-reformat YAML.
- Do not edit encrypted or sensitive files unless the task specifically requires it.
- Do not make opportunistic “best practice” changes across manifests.
- Do not assume the cluster, secrets, or external services are available for validation.
- Do not treat deprecated workflows as the main validation path when they differ from `lint-all.yml`.

## Expected Copilot behavior
- Inspect nearby files first and copy the local pattern.
- Be conservative with infrastructure changes.
- If validation cannot be completed locally because secrets or environment state are missing, say that plainly.
- When in doubt, preserve the existing approach instead of introducing a new pattern.
