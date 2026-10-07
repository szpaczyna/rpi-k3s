#!/bin/sh
# Executable dynamic inventory: decrypts inventory.enc.yaml with sops and
# converts the resulting nested YAML tree into the flat JSON schema
# ansible-core expects from an executable inventory script
# (https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html#tuning-the-external-inventory-script).
set -eu

cd "$(dirname "$0")"

sops --decrypt --output-type yaml inventory.enc.yaml | python3 inventory_transform.py
