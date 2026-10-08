#!/bin/sh
# Installs Python requirements (requirements.txt) and Ansible Galaxy
# collections/roles (requirements.yml) into the currently active virtualenv.
#
# Create and activate the virtualenv yourself first, then run this script
# from provision/ansible/:
#
#   python3 -m venv .venv && . .venv/bin/activate
#   ./setup-venv.sh
set -eu

cd "$(dirname "$0")"

pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
ansible-galaxy role install -r requirements.yml
