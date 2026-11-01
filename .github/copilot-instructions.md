This repository is infrastructure-as-code for a Raspberry Pi k3s homelab. Treat it as a Kubernetes, Helm, YAML, shell, and Ansible repository first.

## Scope and priorities

- Prefer the smallest possible change that satisfies the request.
- Follow the structure and conventions already used in the target directory.
- Do not introduce new tooling, frameworks, directory layouts, or naming schemes unless explicitly requested.
- Do not refactor unrelated files while making localized infrastructure changes.
- State assumptions when a request has several plausible readings; ask instead of guessing.

## Repository layout

- `cluster/helm`: local Helm charts and chart-specific resources (values, deploy scripts, encrypted secrets).
- `cluster/backup`: backup CronJobs and related config.
- `scripts`: shell utilities and cluster automation (`deploy_template.sh`, `sops-check.sh`).
- `provision/ansible`: Ansible provisioning for nodes and cluster bootstrap.
- `docs`: GitHub Pages documentation site.
- `assets`: logos and images.
- `WiP`: work-in-progress notes and migration material; not deployed.
- `.github/workflows/lint-all.yml`: primary CI validation workflow.

## YAML and manifest rules

- Preserve existing YAML style, ordering, and indentation. Use 2 spaces.
- Avoid formatting churn in unrelated keys or files.
- Prefer consistency with neighboring manifests over generic Kubernetes style advice.
- Do not add labels, annotations, probes, affinities, security settings, or resource limits unless required by the task or already established nearby.
- Do not remove existing fields unless the change requires it.
- Keep list and resource ordering consistent with the surrounding file.

## Helm rules

- Keep chart structure unchanged unless the task explicitly requires chart restructuring.
- Preserve current values names, helper names, and template layout.
- Prefer simple templates over complex conditionals or indirection.
- Do not rename chart values or move settings between `values.yaml`, `values-public.yaml`, `values.enc.yaml`, and templates unless explicitly requested.
- Some charts intentionally do not have a standard `values.yaml`; do not add one just to satisfy tooling unless the task requires it.
- When changing a chart, prefer patterns already used in that chart over patterns from other charts.
- Chart deploy scripts follow `scripts/deploy_template.sh`: keep `set -euo pipefail`, the `HELM_ARGS` array pattern, and namespace creation before Helm runs.

## Secrets rules

- Never expose, decrypt, or rewrite secrets in plaintext.
- Treat any file matching `*secret.yaml` or `*.enc.*` as sensitive (including `*.enc.yaml`, `*.enc.sql`, `*.enc.sh`).
- Preserve existing secret-management workflows and file boundaries.
- Do not copy secret values into public values files, templates, README files, comments, or examples.
- If a change depends on secret content that is not available, state the limitation instead of inventing values.
- Encrypted files are SOPS ciphertext: do not reformat or lint them as YAML.

## Shell rules

- Keep shell changes minimal and compatible with the existing script style.
- Prefer portable shell patterns unless a script already relies on bash-specific behavior.
- Keep quoting explicit and avoid risky command substitutions or broad globbing changes.
- Do not rewrite shell scripts into another language.
- Python work uses pyenv; never install into global or system Python.

## Ansible rules

- Provisioning lives under `provision/ansible`; lint with `ansible-lint --profile production .` run from that directory.
- Respect `.ansible-lint` and existing role structure; do not add roles or change inventory handling unless requested.

## CI and validation rules

- Treat `.github/workflows/lint-all.yml` as the primary source of truth for validation behavior.
- Keep changes compatible with existing checks: yamllint, shellcheck, kubeconform, kube-linter, chart testing, and ansible-lint.
- Do not change CI workflows or linter configs unless the task is specifically about CI or linting.
- Respect current repository tradeoffs: some kube-linter findings are intentionally excluded and should not be "fixed" unless requested.
- Respect existing yamllint ignores and conventions instead of trying to normalize all YAML in the repo.
- Markdown lint is informational (non-blocking); do not chase markdownlint warnings unless asked.

## Commands to prefer

- Prefer existing repo commands before inventing new ones:
  - `make <component>` (deploy a single component), `make all`, `make helm-update`, `make enc`, `make help`
  - `pre-commit run --all-files` (or a named hook) for local validation
  - `helm lint <chart-dir>` and `helm template <release-name> <chart-dir>` for Helm changes
  - `scripts/sops-check.sh <files>` to verify `.enc.*` files are encrypted
  - `ansible-lint --profile production .` from `provision/ansible`
- Do not rely on `npm` scripts; this repo has no `package.json` scripts.

## Git and commit conventions

- Use SSH remotes, never HTTPS.
- Never commit without showing the commit message and waiting for approval.
- Never add AI attribution (e.g. `Co-Authored-By`) to commits, PRs, or messages.
- Do not stash, reset, or overwrite unrelated local changes; ask how to preserve them.

## Writing style

- Lead with the answer or outcome; no throat-clearing openers.
- No sycophancy or filler acknowledgments; correct mistakes directly.
- Active voice with a named actor; avoid false agency.
- No em dashes; use a comma, colon, parenthesis, or period.
- Avoid banned filler words (really, just, literally, actually, simply, etc.) and unqualified extremes (always, never, every).

## What to avoid

- Do not mass-reformat YAML.
- Do not edit encrypted or sensitive files unless the task specifically requires it.
- Do not make opportunistic "best practice" changes across manifests.
- Do not assume the cluster, secrets, or external services are available for validation.
- Do not treat deprecated workflows as the main validation path when they differ from `lint-all.yml`.
- Do not edit files under `WiP/` unless the task is explicitly about them.

## Expected Copilot behavior

- Inspect nearby files first and copy the local pattern.
- Be conservative with infrastructure changes.
- Read before editing; prefer the narrowest change.
- Ask before destructive, credential, publish, or infra-mutating commands.
- If validation cannot be completed locally because secrets or environment state are missing, say that plainly.
- When in doubt, preserve the existing approach instead of introducing a new pattern.
