#!/bin/sh
# Installs Python requirements (requirements.txt) and Ansible Galaxy
# collections (requirements.yml) into the currently active virtualenv.
#
# Create and activate the virtualenv first, then run this from
# provision/ansible/. Anything that auto-activates on directory change works
# too, e.g. the autoswitch_virtualenv zsh plugin:
#
#   python3 -m venv .venv && . .venv/bin/activate
#   ./setup-venv.sh
set -eu

cd "$(dirname "$0")"

# Without this, pip quietly installs into the user's system Python and the
# ansible binaries end up outside the venv, where ansible-playbook and
# ansible-lint disagree about what is installed.
if [ -z "${VIRTUAL_ENV:-}" ]; then
    echo "setup-venv.sh: no active virtualenv (VIRTUAL_ENV is unset)." >&2
    echo "Activate one first, e.g. . .venv/bin/activate" >&2
    exit 1
fi

pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
ansible-galaxy role install -r requirements.yml
