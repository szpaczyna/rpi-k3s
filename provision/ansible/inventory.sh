#!/bin/sh
# Executable dynamic inventory: decrypts inventory.enc.yaml with sops and
# converts the resulting nested YAML tree into the flat JSON schema
# ansible-core expects from an executable inventory script
# (https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html#tuning-the-external-inventory-script).
set -eu

cd "$(dirname "$0")"

# PyYAML is pinned in requirements.txt, so it only exists inside the virtualenv.
# Plain `python3` resolves to the system interpreter, which has no yaml module
# and fails with ModuleNotFoundError. Prefer the active virtualenv's interpreter
# and fall back to a plain python3 only when there is none.
PYTHON="${VIRTUAL_ENV:+$VIRTUAL_ENV/bin/python3}"
: "${PYTHON:=python3}"

sops --decrypt --output-type yaml inventory.enc.yaml | "$PYTHON" inventory_transform.py
