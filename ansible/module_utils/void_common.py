# -*- coding: utf-8 -*-
"""Shared helpers for the void_* modules in ansible/library/.

Imported by modules as `from ansible.module_utils.void_common import ...`;
Ansible ships this file to the target alongside the module.
"""

from __future__ import annotations

import re

_VERSION_SPLIT = re.compile(r"[<>=]")


def run(module, cmd, check_rc=True, **kwargs):
    """Run CMD (a list); fail the module with full output if CHECK_RC and rc != 0."""
    rc, out, err = module.run_command(cmd, **kwargs)
    if check_rc and rc != 0:
        module.fail_json(
            msg=f"command failed (rc={rc}): {' '.join(cmd)}",
            rc=rc, stdout=out, stderr=err, cmd=cmd,
        )
    return rc, out, err


def lines(text):
    """Non-empty stripped lines of TEXT."""
    return [ln.strip() for ln in text.splitlines() if ln.strip()]


def strip_version(dep):
    """'python>=3.10' -> 'python'."""
    return _VERSION_SPLIT.split(dep, maxsplit=1)[0].strip()


def pacman_unsatisfied(module, pacman, names):
    """Names (dependency strings) not satisfied by installed packages or their provides."""
    if not names:
        return []
    rc, out, err = module.run_command([pacman, "-T", *names])
    # rc 0: all satisfied; rc 127: some missing (printed one per line).
    if rc not in (0, 127):
        module.fail_json(msg="pacman -T failed", rc=rc, stdout=out, stderr=err)
    return lines(out)


def pacman_not_in_repos(module, pacman, names):
    """Subset of NAMES that no enabled sync repository provides."""
    if not names:
        return []
    rc, out, err = module.run_command([pacman, "-Sp", "--print-format", "%n", *names])
    if rc == 0:
        return []
    unknown = re.findall(r"target not found: (\S+)", err)
    if not unknown:
        module.fail_json(msg="pacman -Sp failed", rc=rc, stdout=out, stderr=err)
    return unknown
