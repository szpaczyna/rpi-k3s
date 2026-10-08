#!/usr/bin/env python3
"""Flatten the nested group/children/hosts YAML tree produced by `sops
--decrypt` into the flat JSON schema ansible-core expects from an
executable inventory script. Reads YAML on stdin, writes JSON on stdout.
"""
import json
import sys

import yaml


def walk(node, groups, hostvars, name=None):
    if name is not None:
        groups.setdefault(name, {"hosts": [], "children": []})
    for hostname, hvars in (node.get("hosts") or {}).items():
        hostvars[hostname] = hvars or {}
        if name is not None:
            groups[name]["hosts"].append(hostname)
    for child_name, child_node in (node.get("children") or {}).items():
        if name is not None:
            groups[name]["children"].append(child_name)
        walk(child_node, groups, hostvars, child_name)


def main():
    data = yaml.safe_load(sys.stdin) or {}
    groups = {}
    hostvars = {}
    walk(data.get("all", {}), groups, hostvars)

    result = {}
    for group_name, group_data in groups.items():
        entry = {}
        if group_data["hosts"]:
            entry["hosts"] = group_data["hosts"]
        if group_data["children"]:
            entry["children"] = group_data["children"]
        result[group_name] = entry

    result["all"] = {"children": list(groups.keys())}
    result["_meta"] = {"hostvars": hostvars}

    json.dump(result, sys.stdout)


if __name__ == "__main__":
    main()
