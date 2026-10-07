# Ansible Provisioning

Ansible playbooks and roles that provision the Raspberry Pi hosts: the k3s
cluster (master + workers) and the Pi-hole box. Everything here is meant to
be re-run safely (idempotent tasks), not just for first-time setup.

## Quick start

```bash
# From provision/ansible/, with a venv active and dependencies installed
# (see Requirements below):

# Base OS setup (system role + dotfiles) on the k3s cluster
ansible-playbook playbooks/base_setup.yml

# Base OS setup on the Pi-hole host
ansible-playbook playbooks/pihole_setup.yml

# Install k3s (server + agents) and fetch kubeconfig to ~/.kube/config-k3s
ansible-playbook playbooks/kubernetes/k3s-install.yml

# View/edit the encrypted inventory
sops -d inventory.enc.yaml      # view only
sops inventory.enc.yaml         # edit (re-encrypts on save)

# Opt-in full apt upgrade (not part of base_setup.yml)
ansible-playbook playbooks/apt.yaml
```

## Requirements

- `ansible-core`, `ansible-lint`, and the `docker` Python package are pinned
  in `requirements.txt`.
- Ansible Galaxy collections (`ansible.posix`, `community.docker`,
  `community.general`, `kubernetes.core`, `community.sops`) and the
  `mrlesmithjr.zfs` role are pinned in `requirements.yml`.
- `sops` CLI installed locally, with access to the PGP key listed in
  `.sops.yaml` (repo root) — needed to decrypt the inventory and any
  SOPS-encrypted `group_vars`.

Install everything into an already-active virtualenv:

```bash
python3 -m venv .venv && . .venv/bin/activate
./setup-venv.sh
```

## Inventory (SOPS-encrypted)

The inventory isn't a plain `inventory.ini`/`.yml` file. It's fully
SOPS-encrypted so the file is safe to commit without exposing the home
network's IP topology:

- `inventory.enc.yaml` — the whole YAML tree (`all.children.{k3s_cluster,
  pihole}` etc., each group with `hosts:` and `ansible_host:`) encrypted at
  rest with `sops`.
- `inventory.sh` — the executable dynamic inventory script Ansible actually
  calls (set via `ansible.cfg`'s `inventory = ./inventory.sh`). It decrypts
  `inventory.enc.yaml` with `sops --decrypt` and pipes the result into
  `inventory_transform.py`.
- `inventory_transform.py` — flattens the nested `children`/`hosts` YAML tree
  into the flat JSON schema (`{"group": {"hosts": [...], "children": [...]}
  , "_meta": {"hostvars": {...}}}`) that ansible-core expects from an
  executable inventory script.

To edit hosts/groups:

```bash
sops inventory.enc.yaml      # opens decrypted content in $EDITOR, re-encrypts on save
sops -d inventory.enc.yaml   # decrypt to stdout only, no edit
```

## SOPS secrets in group_vars

`group_vars/k3s_cluster/registries.enc.sops.yml` holds the Docker registry
credentials (`k3s_registries_docker_io_username`/`_password`) used to render
`/etc/rancher/k3s/registries.yaml` on every cluster node (role `k3s`, task
`registries.yml`). Unlike the inventory above, this file is decrypted
automatically by the `community.sops` vars plugin (enabled through
`vars_plugins_enabled` in `ansible.cfg`). Leave the plugin's stage at its
default: with `vars_stage = inventory`, the raw ciphertext that
`host_group_vars` loads from the same file at task time wins over the
decrypted values. The plugin only loads files ending in `.sops.yml`,
`.sops.yaml` or `.sops.json`, hence the `.enc.sops.yml` name: `.enc.` keeps
it under the repo's `ensure-sops` pre-commit check.

To edit:

```bash
sops group_vars/k3s_cluster/registries.enc.sops.yml
```

## Roles

| Role | Applies to | What it does |
|------|------------|---------------|
| `system` | `k3s_cluster`, `pihole` | Base OS config: kernel modules (`br_netfilter`/`overlay`/`rbd` for k3s), smartd, inotify limits, locale/timezone, network sysctl for the container runtime, apt packages (`system_apt_install_packages` in `defaults/main.yml`), unattended-upgrades, chrony, a static `/etc/hosts` (template `templates/hosts.j2`), sysctl `99-local`, auditd rules, kernel module hardening, journald config, and zram swap. |
| `apt_upgrade` | opt-in only | Full `apt upgrade: full` + autoremove/autoclean. Not included by any playbook by default — see [apt_upgrade](#apt_upgrade-opt-in) below. |
| `k3s` | `k3s_cluster` | Installs k3s via the upstream `get.k3s.io` script (server on `k3s_master`, agent on `k3s_worker`), and renders `/etc/rancher/k3s/registries.yaml` from the SOPS secret above. |
| `pihole` | `pihole` | Manages only the Pi-hole v6 config *deviations* from default (via `pihole-FTL --config`), plus adlists in `gravity.db`. |
| `gentoo_portage` | `gentoo` | Portage config for Gentoo hosts: `make.conf`, `package.use`, `package.accept_keywords/old`, `package.mask`. |
| `dotfiles` | `k3s_cluster`, `pihole`, `gentoo` | Shared shell/editor setup: zsh (zshrc + plugins), tmux, fastfetch, neovim. |

### `system`

Each task file in `roles/system/tasks/main.yml` is included under its own
tag:

| Tag | File | Purpose |
|-----|------|---------|
| `kernel` | `kernel.yml` | Kernel modules needed by k3s/containerd |
| `disks` | `disks.yml` | smartd disk monitoring |
| `filesystem` | `filesystem.yml` | Filesystem/inotify limits |
| `locale` | `locale.yml` | Locale and timezone |
| `network` | `network.yml` | Network sysctl for the CRI |
| `packages` | `packages.yml` | Apt packages (install/remove lists) |
| `unattended-upgrades` | `unattended-upgrades.yml` | Unattended security upgrades |
| `chrony` | `chrony.yml` | NTP via chrony |
| `hosts` | `hosts.yml` | Static `/etc/hosts` (see below) |
| `sysctl` | `sysctl.yml` | `99-local.conf` sysctl overrides |
| `auditd` | `auditd.yml` | auditd rules (`files/auditd/*.rules`) |
| `hardening` | `hardening.yml` | Kernel module hardening |
| `journald` | `journald.yml` | journald config |
| `zram` | `zram.yml` | zram swap, via `StuartIanNaylor/zram-swap-config` |

The static `/etc/hosts` exists because k3s nodes join each other by DNS name
(`rpi-k3s-master-00`, not IP — see `roles/k3s/tasks/agent.yml`), and Pi-hole
itself doesn't use its own DNS for name resolution on the host it runs on.

Zram swap runs on every host, but `swappiness` differs by role: `0` on
`k3s_master`, `10` elsewhere, enforced via `expected_swappiness` in
`tasks/zram.yml` (the zram service starts after `systemd-sysctl`, so it has
the final say over the value).

### `apt_upgrade` (opt-in)

Deliberately **not** wired into `base_setup.yml` or `pihole_setup.yml`.
Run it through its own playbook when you want a one-off full upgrade outside
routine provisioning:

```bash
ansible-playbook playbooks/apt.yaml
```

### `k3s`

Replaces the previous dependency on the `xanmanning.k3s` Galaxy role (no
longer in `requirements.yml`) with a thin role that calls the upstream
`curl https://get.k3s.io | sh` installer directly:

- **Server** (`tasks/server.yml`, hosts in `k3s_master`): installs with
  `INSTALL_K3S_EXEC` matching flannel vxlan backend, `traefik`/`servicelb`/
  `local-path` disabled, `--write-kubeconfig-mode 644`, data dir `/k3s`
  (`k3s_server_exec_args` / `k3s_data_dir` in `defaults/main.yml`). After
  install it reads the join token from `{{ k3s_data_dir }}/server/token` and
  exposes it as a cacheable fact (`k3s_token`).
- **Agent** (`tasks/agent.yml`, hosts in `k3s_worker`): joins the master by
  DNS name (`https://rpi-k3s-master-00:6443`, from
  `hostvars[groups['k3s_master'][0]].inventory_hostname`) using the token
  read via `hostvars` from the master's play facts. This DNS join relies on
  the static `/etc/hosts` deployed by the `system` role.
- **Registries** (`tasks/registries.yml`): always runs, before the
  server/agent install because k3s reads the file only at startup. Renders
  `/etc/rancher/k3s/registries.yaml` from `templates/registries.yaml.j2`
  using the credentials in `group_vars/k3s_cluster/registries.enc.sops.yml`
  (see [SOPS secrets](#sops-secrets-in-group_vars) above), and restarts
  `k3s`/`k3s-agent` through the `Restart k3s` handler when the file changes.

### `pihole`

Manages only the config keys that deviate from Pi-hole v6 defaults via
`pihole-FTL --config <dotted.key> <value>` — not the whole `pihole.toml`,
since FTL regenerates that file (with comments) on every upgrade and a full
template would drift. Each `tasks/*.yml` file (`dns-config.yml`,
`database-config.yml`, `webserver-config.yml`) first reads the current value
and only writes when it differs from the desired one in
`defaults/main.yml`.

Adlists are managed separately in `tasks/adlists.yml` via `sqlite3` upserts
into `gravity.db` (`pihole-FTL` has no idempotent "add adlist" subcommand in
v6), with the `Reload pihole gravity` handler (`pihole -g`) firing only when
an adlist actually changed.

### `gentoo_portage`

Manages Portage config on the Gentoo hosts (`make.conf`, `package.use/`,
`package.accept_keywords/old/`, `package.mask/`), each driven by a list in
`defaults/main.yml` (`gentoo_portage_package_use`,
`gentoo_portage_package_accept_keywords`) and copied from the matching
`files/` subdirectory. `package.accept_keywords` entries live under an
`old/` subdirectory, keeping them visually separate from any current
keyword unmasks that might get added later.

### `dotfiles`

Shared between `k3s_cluster`, `pihole`, and `gentoo`. Installs zsh (zshrc +
plugins from `files/zsh-plugins/`), tmux, fastfetch, and neovim (config
`files/init.vim` with vim-plug, headless `PlugInstall`), with `vim` aliased
to `nvim` and `~/.vimrc` symlinked to `~/.config/nvim/init.vim`.

On Debian hosts (`k3s_cluster`, `pihole`) `zsh.yml`/`nvim.yml` install
`zsh-syntax-highlighting`/`neovim` via apt; on `gentoo` those tasks are
skipped (`when: "'gentoo' not in group_names"`) since Portage owns package
installation there — see `gentoo_portage` below.

The zshrc and neovim config sources are parametrized
(`dotfiles_zshrc_src`/`dotfiles_nvim_init_src`, default `zshrc`/`init.vim`
in `defaults/main.yml`), so `group_vars/gentoo.yml` can point them at
`zshrc-gentoo`/`init-gentoo.vim` instead.

The default zsh plugin list (`dotfiles_zsh_plugins` in `defaults/main.yml`)
includes `kubectl`/`helm`/`kubetail` plugins, which only make sense on the
k3s cluster. `group_vars/pihole.yml` and `group_vars/gentoo.yml` each
override the list without those plugins (and without `forgit`/`zsh_reload`/
`zsh-z` on `gentoo`). `k3s_cluster` has its own override at
`group_vars/k3s_cluster/dotfiles.yml` instead of a flat
`group_vars/k3s_cluster.yml` — that group's vars live in a directory because
`registries.enc.sops.yml` needed to sit next to it.

## Playbooks

| Playbook | Hosts | Roles called |
|----------|-------|---------------|
| `playbooks/base_setup.yml` | `k3s_cluster` | `system`, `dotfiles` |
| `playbooks/pihole_setup.yml` | `pihole` | `system`, `dotfiles`, `pihole` |
| `playbooks/gentoo_setup.yml` | `gentoo` | `gentoo_portage`, `dotfiles` |
| `playbooks/apt.yaml` | `k3s_cluster` | `apt_upgrade` (opt-in, see above) |
| `playbooks/kubernetes/k3s-install.yml` | `k3s_cluster` | `k3s` |
| `playbooks/kubernetes/k3s-nuke.yml` | `k3s_cluster` | — (runs `k3s-killall.sh`/`k3s-uninstall.sh` directly) |

`k3s-install.yml` also fetches `/etc/rancher/k3s/k3s.yaml` from the master,
rewrites `cluster.name`/`context.name`/`current-context` from `default` to
`rpi-k3s` (the `user`/`users[0].name` entry stays `default`), and points
`server:` at `k3s_registration_address` instead of `127.0.0.1` — this is a
*local* kubeconfig for the operator's machine, so it uses the registration
IP rather than the DNS name agents use to join the cluster. The result is
written to `~/.kube/config-k3s`, backing up any existing file to
`~/.kube/config-k3s.bak` first.

`k3s_registration_address` is defined in `vars.yml` (`10.0.0.9`), but
`k3s-install.yml` doesn't load that file via `vars_files` the way
`base_setup.yml` does — pass it explicitly if it isn't set some other way,
e.g. `ansible-playbook playbooks/kubernetes/k3s-install.yml -e @../vars.yml`.

`k3s-nuke.yml` tears the cluster down (`k3s-killall.sh`, then the
`*-uninstall.sh` scripts, then removes leftover CNI files under
`/etc/cni/net.d`).

## Linting

`ansible-lint` runs as a pre-commit hook (`.pre-commit-config.yaml`, repo
root) against `provision/ansible/` with the `production` profile. Before
committing:

```bash
ansible-lint provision/ansible/ --profile production
ansible-playbook <playbook> --syntax-check
```

Don't run `--check --diff` against the live hosts as part of this flow —
that's a manual, deliberate step when you actually need it, not something to
automate.

### Known issue: `--check --diff` crashes under Python 3.14

With `ansible-core` 2.21.5 and `community.general` 3.8.0 running on
CPython 3.14, `ansible-playbook` crashes on startup with:

```
TypeError: function() argument 'code' must be code, not str
```

raised from `community.general`'s YAML stdout callback plugin
(`plugins/callback/yaml.py`), triggered by `stdout_callback = yaml` in
`ansible.cfg`. The callback's `MyDumper` subclass relies on CPython internals
that changed between 3.12 and 3.14; `community.general` 3.8.0 predates that
change.

Workaround — run with the default callback instead of `yaml`:

```bash
ANSIBLE_STDOUT_CALLBACK=default ansible-playbook <playbook> --check --diff
```

This affects only local output formatting, not the hosts or the modules
that run against them. The proper fix is upgrading `community.general` past
the version that fixed this (or running the venv on Python <= 3.13), neither
of which has been done here yet.

### Known issue: `--check` false positive on first-time `zram-swap-config` install

`roles/system/tasks/zram.yml` detects whether `zram-swap-config` is already
installed by checking for `/opt/zram-swap-config/.git`. If that directory is
missing (e.g. the install script already ran once and the clone was cleaned
up afterwards, as on the Pi-hole host), `--check` simulates the `git clone`
step as "changed" without actually cloning anything, then the next task
(`chmod` on `install.sh`) fails because the file genuinely doesn't exist on
disk during a dry run. A real (non-`--check`) run doesn't hit this: the
clone actually happens, so the following steps have something to act on.
This is a limitation of `--check` with any task chain of
`clone → chmod → run`, not a bug in the role — zram-swap-config is already
`enabled`/active on the affected host regardless.
