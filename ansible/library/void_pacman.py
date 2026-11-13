#!/usr/bin/python
# -*- coding: utf-8 -*-
"""void_pacman: Arch repository package management with ansible-core only."""

from __future__ import annotations

DOCUMENTATION = r"""
---
module: void_pacman
short_description: Manage Arch Linux repository packages with pacman
description:
  - Installs, upgrades or removes repository packages, syncs the package
    databases and performs full system upgrades.
  - Self-contained replacement for community.general.pacman so the
    project only depends on ansible-core.
  - Supports check mode; reports C(changed) only when the system was altered.
options:
  name:
    description: Package names (dependency strings such as C(foo>=1.2) are accepted for state=present).
    type: list
    elements: str
    default: []
  state:
    description: C(present) installs missing packages, C(latest) also upgrades listed ones, C(absent) removes them.
    type: str
    choices: [present, absent, latest]
    default: present
  update_cache:
    description: Sync package databases (C(pacman -Sy)) first. Reports changed only if a database was downloaded.
    type: bool
    default: false
  upgrade:
    description: Upgrade every installed package (C(pacman -Su)) after the optional sync.
    type: bool
    default: false
  extra_args:
    description: Extra arguments appended to install/upgrade/remove transactions.
    type: str
    default: ""
author: void-dots
"""

EXAMPLES = r"""
- name: Install packages
  void_pacman:
    name: [git, fish]

- name: Sync databases and fully upgrade
  void_pacman:
    update_cache: true
    upgrade: true
"""

RETURN = r"""
packages:
  description: Packages installed, upgraded or removed (or that would be, in check mode).
  returned: always
  type: list
  elements: str
cache_updated:
  description: Whether a database sync downloaded anything.
  returned: always
  type: bool
stdout:
  description: Output of the last pacman transaction.
  returned: always
  type: str
"""

import shlex

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.void_common import (
    lines,
    pacman_not_in_repos,
    pacman_unsatisfied,
    run,
)


def sync_databases(module, pacman):
    _, out, _ = run(module, [pacman, "-Sy"])
    # Every repo prints "<repo> is up to date" when nothing was downloaded.
    repo_lines = [ln for ln in lines(out) if not ln.startswith("::")]
    return any("is up to date" not in ln for ln in repo_lines), out


def pending_upgrades(module, pacman, names=None):
    rc, out, err = module.run_command([pacman, "-Qu", *(names or [])])
    if rc not in (0, 1):
        module.fail_json(msg="pacman -Qu failed", rc=rc, stdout=out, stderr=err)
    return [ln.split()[0] for ln in lines(out) if "[ignored]" not in ln]


def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type="list", elements="str", default=[]),
            state=dict(type="str", default="present", choices=["present", "absent", "latest"]),
            update_cache=dict(type="bool", default=False),
            upgrade=dict(type="bool", default=False),
            extra_args=dict(type="str", default=""),
        ),
        supports_check_mode=True,
    )
    p = module.params
    pacman = module.get_bin_path("pacman", required=True)
    extra = shlex.split(p["extra_args"])
    result = dict(changed=False, packages=[], cache_updated=False, stdout="")

    if p["update_cache"] and not module.check_mode:
        result["cache_updated"], result["stdout"] = sync_databases(module, pacman)
        result["changed"] = result["cache_updated"]

    if p["upgrade"]:
        upgrades = pending_upgrades(module, pacman)
        if upgrades:
            result["changed"] = True
            result["packages"].extend(upgrades)
            if not module.check_mode:
                _, result["stdout"], _ = run(module, [pacman, "-Su", "--noconfirm", *extra])

    names = p["name"]
    if names and p["state"] in ("present", "latest"):
        missing = pacman_unsatisfied(module, pacman, names)
        unknown = pacman_not_in_repos(module, pacman, missing)
        if unknown:
            module.fail_json(msg=f"package(s) not found in any enabled repository: {', '.join(unknown)}",
                             packages=unknown)
        to_install = list(missing)
        if p["state"] == "latest":
            installed = [n for n in names if n not in missing]
            to_install += pending_upgrades(module, pacman, installed) if installed else []
        if to_install:
            result["changed"] = True
            result["packages"].extend(to_install)
            if not module.check_mode:
                _, result["stdout"], _ = run(
                    module, [pacman, "-S", "--needed", "--noconfirm", *extra, *to_install])

    elif names and p["state"] == "absent":
        _, out, _ = run(module, [pacman, "-Qq"])
        installed = set(lines(out))
        to_remove = [n for n in names if n in installed]
        if to_remove:
            result["changed"] = True
            result["packages"].extend(to_remove)
            if not module.check_mode:
                _, result["stdout"], _ = run(module, [pacman, "-Rs", "--noconfirm", *extra, *to_remove])

    module.exit_json(**result)


if __name__ == "__main__":
    main()
