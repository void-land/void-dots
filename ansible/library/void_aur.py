#!/usr/bin/python
# -*- coding: utf-8 -*-
"""void_aur: build and install AUR packages with makepkg, no AUR helper."""

from __future__ import annotations

DOCUMENTATION = r"""
---
module: void_aur
short_description: Build and install AUR packages without an AUR helper
description:
  - For every requested package that is not installed, looks it up on the
    AUR RPC, installs its repository dependencies with pacman, clones the
    AUR git repo and runs makepkg as an unprivileged build user, then
    installs the built package with pacman -U as root.
  - Must run as root (become). The build itself never runs as root and never
    calls sudo, so no password prompt or sudoers change is needed.
  - Dependencies that only exist on the AUR are not resolved; the module
    fails naming them.
  - Supports check mode (stops after the AUR lookup).
options:
  name:
    description: AUR package names.
    type: list
    elements: str
    required: true
  build_user:
    description: Non-root user that clones and builds the packages.
    type: str
    required: true
  build_dir:
    description: Directory holding the per-package clones. Defaults to C(~build_user/.cache/void-dots/aur).
    type: str
  state:
    description: Only C(present) is supported (install if missing, never rebuild).
    type: str
    choices: [present]
    default: present
  aur_url:
    description: AUR base URL (RPC and git).
    type: str
    default: https://aur.archlinux.org
  timeout:
    description: AUR RPC timeout in seconds.
    type: int
    default: 30
author: void-dots
"""

EXAMPLES = r"""
- name: Install AUR packages
  void_aur:
    name: [yay, vscodium-bin]
    build_user: alice
"""

RETURN = r"""
packages:
  description: Packages built and installed (or that would be, in check mode).
  returned: always
  type: list
  elements: str
deps_installed:
  description: Repository dependencies installed for the builds.
  returned: always
  type: list
  elements: str
"""

import json
import os
import pwd
import urllib.error
import urllib.parse
import urllib.request

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.void_common import (
    lines,
    pacman_not_in_repos,
    pacman_unsatisfied,
    run,
    strip_version,
)


def aur_info(module, base_url, names, timeout):
    query = urllib.parse.urlencode([("arg[]", n) for n in names])
    url = f"{base_url}/rpc/v5/info?{query}"
    try:
        with urllib.request.urlopen(url, timeout=timeout) as resp:
            data = json.load(resp)
    except (urllib.error.URLError, OSError, ValueError) as exc:
        module.fail_json(msg=f"AUR RPC request failed ({url}): {exc}. "
                             "Check network/proxy access to the AUR, or skip this step (-x aur).")
    if data.get("type") == "error":
        module.fail_json(msg=f"AUR RPC error: {data.get('error')}", url=url)
    return {pkg["Name"]: pkg for pkg in data.get("results", [])}


def as_user(user, *cmd):
    return ["runuser", "-u", user, "--", *cmd]


def built_package_file(module, user, env, pkgdir, pkgname):
    """Path of the package file makepkg produced for PKGNAME."""
    _, out, _ = run(module, as_user(user, "makepkg", "--packagelist"), cwd=pkgdir, environ_update=env)
    for path in lines(out):
        # <name>-<pkgver>-<pkgrel>-<arch>.pkg.tar.*
        base = os.path.basename(path)
        if base.rsplit("-", 3)[0] == pkgname and os.path.exists(path):
            return path
    module.fail_json(msg=f"makepkg finished but no package file for {pkgname} was found", packagelist=out)


def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type="list", elements="str", required=True),
            build_user=dict(type="str", required=True),
            build_dir=dict(type="str"),
            state=dict(type="str", default="present", choices=["present"]),
            aur_url=dict(type="str", default="https://aur.archlinux.org"),
            timeout=dict(type="int", default=30),
        ),
        supports_check_mode=True,
    )
    p = module.params
    pacman = module.get_bin_path("pacman", required=True)
    result = dict(changed=False, packages=[], deps_installed=[])

    user = p["build_user"]
    if user == "root":
        module.fail_json(msg="build_user must not be root (makepkg refuses to build as root)")
    try:
        pw = pwd.getpwnam(user)
    except KeyError:
        module.fail_json(msg=f"build_user '{user}' does not exist")

    pending = pacman_unsatisfied(module, pacman, p["name"])
    if not pending:
        module.exit_json(**result)

    info = aur_info(module, p["aur_url"].rstrip("/"), pending, p["timeout"])
    unknown = [n for n in pending if n not in info]
    if unknown:
        module.fail_json(msg=f"AUR package(s) not found: {', '.join(unknown)}", packages=unknown)

    result["changed"] = True
    result["packages"] = pending
    if module.check_mode:
        module.exit_json(**result)

    if os.geteuid() != 0:
        module.fail_json(msg="void_aur must run as root (become: true); builds drop to build_user")
    module.get_bin_path("makepkg", required=True)
    module.get_bin_path("git", required=True)

    build_dir = p["build_dir"] or os.path.join(pw.pw_dir, ".cache", "void-dots", "aur")
    env = dict(HOME=pw.pw_dir, USER=user, LOGNAME=user)
    run(module, as_user(user, "mkdir", "-p", build_dir), environ_update=env)

    for name in pending:
        pkg = info[name]

        # Repository dependencies (check() is skipped, so no CheckDepends).
        deps = [strip_version(d) for d in pkg.get("Depends", []) + pkg.get("MakeDepends", [])]
        missing = pacman_unsatisfied(module, pacman, deps)
        aur_only = pacman_not_in_repos(module, pacman, missing)
        if aur_only:
            module.fail_json(msg=f"AUR dependency not supported: {', '.join(aur_only)} (needed by {name}); "
                                 "install it first, e.g. by listing it before this package", **result)
        if missing:
            run(module, [pacman, "-S", "--needed", "--noconfirm", "--asdeps", *missing])
            result["deps_installed"].extend(missing)

        # Clone or refresh the AUR repo as the build user.
        base = pkg.get("PackageBase", name)
        pkgdir = os.path.join(build_dir, base)
        if os.path.isdir(os.path.join(pkgdir, ".git")):
            run(module, as_user(user, "git", "-C", pkgdir, "pull", "--ff-only", "--quiet"), environ_update=env)
        else:
            run(module, as_user(user, "git", "clone", "--quiet", f"{p['aur_url'].rstrip('/')}/{base}.git", pkgdir),
                environ_update=env)

        run(module, as_user(user, "makepkg", "-f", "--noconfirm", "--cleanbuild", "--nocheck"),
            cwd=pkgdir, environ_update=env)
        pkgfile = built_package_file(module, user, env, pkgdir, name)
        run(module, [pacman, "-U", "--needed", "--noconfirm", pkgfile])

    module.exit_json(**result)


if __name__ == "__main__":
    main()
