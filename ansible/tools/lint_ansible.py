#!/usr/bin/env python3
"""Static checks for the void-dots Ansible project (run by ../../lint.sh).

1. Builtin-only policy: every task's module must be ansible.builtin.* or a
   repository-local void_* module (ansible/library/). No requirements.yml,
   no `collections:` keyword.
2. Step consistency: for each profile playbook, the ordered tags of its roles
   (minus `always`) must equal the ids in that hosts group's
   inventory/group_vars/<group>.yml `void_profile_steps`, in the same order.

Only PyYAML is needed (an ansible-core dependency). Exits 1 on any failure.
"""

import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    print("PyYAML not available, skipping Ansible static checks")
    sys.exit(0)

ROOT = Path(__file__).resolve().parent.parent

# Task-level keywords (not modules). with_* loops are handled separately.
TASK_KEYWORDS = {
    "name", "when", "register", "loop", "loop_control", "tags", "become",
    "become_user", "become_method", "become_flags", "become_exe", "vars",
    "args", "notify", "listen", "changed_when", "failed_when",
    "ignore_errors", "ignore_unreachable", "check_mode", "diff",
    "environment", "no_log", "delegate_to", "delegate_facts", "run_once",
    "until", "retries", "delay", "block", "rescue", "always",
    "any_errors_fatal", "throttle", "timeout", "module_defaults",
    "connection", "debugger", "remote_user", "port", "async", "poll",
}
# Plays may carry these instead of tasks.
PLAY_KEYWORDS = {"hosts", "roles", "tasks", "pre_tasks", "post_tasks", "handlers",
                 "gather_facts", "vars_files", "vars_prompt", "serial",
                 "max_fail_percentage", "strategy", "order", "force_handlers",
                 "fact_path", "gather_subset", "gather_timeout"} | TASK_KEYWORDS

errors = []


def allowed_module(mod):
    return mod.startswith("ansible.builtin.") or mod.startswith("void_")


def check_task(task, where):
    if not isinstance(task, dict):
        errors.append(f"{where}: task is not a mapping")
        return
    if "collections" in task:
        errors.append(f"{where}: 'collections:' keyword is not allowed")
    for key in ("block", "rescue", "always"):
        for sub in task.get(key) or []:
            check_task(sub, where)
    if "block" in task:
        return
    if "action" in task or "local_action" in task:
        errors.append(f"{where}: use the module key directly instead of action/local_action")
        return
    modules = [k for k in task if k not in TASK_KEYWORDS and not k.startswith("with_")]
    if len(modules) != 1:
        errors.append(f"{where}: task '{task.get('name', '?')}' has module keys {modules}")
        return
    if not allowed_module(modules[0]):
        errors.append(f"{where}: task '{task.get('name', '?')}' uses '{modules[0]}' "
                      "(only ansible.builtin.* and local void_* modules are allowed)")


def load(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        errors.append(f"{path}: invalid YAML: {exc}")
        return None


def check_task_file(path):
    data = load(path)
    for task in data or []:
        check_task(task, path.relative_to(ROOT))


def check_playbook(path):
    data = load(path)
    for play in data or []:
        if not isinstance(play, dict):
            continue
        rel = path.relative_to(ROOT)
        if "collections" in play:
            errors.append(f"{rel}: 'collections:' keyword is not allowed")
        if "hosts" not in play:
            check_task(play, rel)  # import_playbook entry
            continue
        for key in ("tasks", "pre_tasks", "post_tasks", "handlers"):
            for task in play.get(key) or []:
                check_task(task, rel)


def role_tags(play):
    tags = []
    for role in play.get("roles") or []:
        role_tag = role.get("tags", []) if isinstance(role, dict) else []
        if isinstance(role_tag, str):
            role_tag = [role_tag]
        tags.extend(t for t in role_tag if t != "always")
    return tags


def check_steps():
    gv = ROOT / "inventory" / "group_vars"
    for path in sorted((ROOT / "playbooks").glob("*.yml")):
        for play in load(path) or []:
            if not isinstance(play, dict) or "hosts" not in play:
                continue
            group = play["hosts"]
            data = load(gv / f"{group}.yml") if (gv / f"{group}.yml").exists() else None
            steps = (data or {}).get("void_profile_steps")
            if steps is None:
                errors.append(f"{path.relative_to(ROOT)}: no void_profile_steps in group_vars/{group}.yml")
                continue
            ids = [s["id"] for s in steps]
            tags = role_tags(play)
            if ids != tags:
                errors.append(f"{path.relative_to(ROOT)}: role tags {tags} != "
                              f"group_vars/{group}.yml void_profile_steps {ids}")
    # Debian and Ubuntu must keep identical steps (inherited from vps.yml).
    for child in ("debian_vps", "ubuntu_vps"):
        data = load(gv / f"{child}.yml") or {}
        if "void_profile_steps" in data:
            errors.append(f"group_vars/{child}.yml must not override void_profile_steps (set it in vps.yml)")


def main():
    if any(ROOT.rglob("requirements.yml")):
        errors.append("requirements.yml found: Galaxy content is not allowed")
    for sub in ("tasks", "handlers"):
        for path in sorted(ROOT.glob(f"roles/*/{sub}/*.yml")):
            check_task_file(path)
    for path in [ROOT / "site.yml", *sorted((ROOT / "playbooks").glob("*.yml"))]:
        check_playbook(path)
    check_steps()

    for err in errors:
        print(f"✗ {err}")
    if errors:
        sys.exit(1)
    print("builtin-only modules and profile steps OK")


if __name__ == "__main__":
    main()
