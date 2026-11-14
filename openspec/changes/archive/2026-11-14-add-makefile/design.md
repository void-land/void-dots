# Design

## Context

The repo root holds `stow.sh` (getopts: `-s`, `-u`, `-n`), `lint.sh` (`-w`) and `bootstrap.sh`, plus `ansible/` with `ansible.cfg`, `inventory/local.yml` (hosts `local-arch`, `local-debian`, `local-ubuntu`), the git-ignored `inventory/hosts.yml` (template `hosts.example.yml`), and two playbooks: `playbooks/arch_desktop.yml` and `playbooks/vps.yml`. The builtin-only policy only holds when `ANSIBLE_CONFIG` points at `ansible/ansible.cfg` (CLAUDE.md, README "Run locally"). `bootstrap.sh` already covers the first-run case: it installs prerequisites, pulls the repo and shows pickers. VPS profiles need `void_target_user` (preflight fails without it). The Arch profile defaults to the invoking user. Requirements are in `specs/task-runner/spec.md`.

## Goals / Non-Goals

**Goals:**
- Each target is a one- or two-line recipe calling an existing script or `ansible-playbook`. No provisioning or linking logic is duplicated in make.
- Target names and variables are short and predictable, and every target is listed by `make help`.

**Non-Goals:**
- Replacing `bootstrap.sh`, its pickers, its prerequisite install or its repo pull.
- Docker targets or a Dockerfile.
- Writing `ANSIBLE_LOG_PATH` or a vars file the way `bootstrap.sh` does. Users who want that pass `ARGS`.
- Portability to BSD make. GNU make is the target on every supported distro.

## Decisions

**Repo-relative paths from the Makefile's own location.** `REPO := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))`, and recipes call `$(REPO)/stow.sh` and `cd $(REPO)/ansible && …`. This mirrors `stow.sh` and `lint.sh`, which resolve the repo from `BASH_SOURCE`, and makes `make -C`/`-f` work. Relying on the CWD would break `make -f ~/.void-dots/Makefile`.

**`ANSIBLE_CONFIG` set inline on every `ansible-playbook` call** (`ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" ansible-playbook …`, with `ANSIBLE_CONFIG := $(REPO)/ansible/ansible.cfg` in the Makefile). The makefile assignment overrides an inherited environment variable, and the inline prefix makes the config path visible in `make -n` output, so a stray `ANSIBLE_CONFIG` in the user's shell can't disable the builtin-only policy. This is preferred over `export ANSIBLE_CONFIG := …`, which works but is invisible in `make -n`. Recipes `cd` into `ansible/` so `-i inventory/local.yml` and `playbooks/*.yml` read exactly as in the README.

**One shared command prefix for all Ansible targets.** One variable builds the option tail:
`$(if $(filter 1 yes true,$(CHECK)),--check) $(if $(TAGS),--tags $(TAGS)) $(if $(SKIP),--skip-tags $(SKIP)) $(if $(TARGET_USER),-e void_target_user=$(TARGET_USER)) $(ARGS)`.
`CHECK` is matched with `filter`, so `CHECK=0` does not turn on a dry run. `ARGS` is expanded unquoted into the recipe, so the shell word-splits it the way the user typed it.
- `TARGET_USER`, not `USER`: `USER` is always set in the environment and would silently become the VPS target user.
- `SKIP`, not `SKIP_TAGS`: shorter, and it matches `bootstrap.sh -x`'s meaning.

**Become prompt: `BECOME ?= $(if $(filter 0,$(shell id -u)),,-K)` for local targets.** This matches `bootstrap.sh`: Arch runs as the user with `--ask-become-pass`, root needs nothing. It is `?=` so a user with passwordless sudo can pass `BECOME=`. `vps` does not add `-K` by default. The connection user and become password come from the remote inventory/host_vars (README "Push to a VPS"). `ARGS=-K` covers the rest.

**Guards for `vps` in make, not the shell.** `$(if $(HOST),,$(error …))` and a `test -f inventory/hosts.yml || { echo …; exit 1; }` line run before `ansible-playbook`, so a missing input fails fast with a message that names the fix.
- Alternative: let Ansible fail on an empty `-l`. Rejected, because `-l ''` applies to *every* host in `hosts.yml`.
- The `HOST` check goes inside the `vps` recipe via a guard prerequisite, not at parse time, so `make help` still works without `HOST`.

**`restow` as two recipe lines** (`stow.sh $(N) -u`, then `stow.sh $(N) -s`). Make stops at the first failing line, so this meets the "stop if unstow fails" requirement without a `-u` + `-s` mode in `stow.sh`. `N := $(if $(filter 1 yes true,$(DRY)),-n)`.

**Help from `##` comments.** Each public target line carries `target: ## description`. `help` greps the Makefile for those lines, formats them with `awk`, and then prints a static variables block. Descriptions sit next to their targets, so they don't drift. Internal targets (guards) carry no `##` and stay hidden. `.DEFAULT_GOAL := help`, and all targets are `.PHONY`.

## Risks / Trade-offs

- [Minimal Debian/Ubuntu images ship without `make`] → `bootstrap.sh` stays the documented first-run path. The README notes that `make` is a convenience once the repo is cloned (`apt install make`).
- [Makefile recipes require tabs; an editor converting to spaces breaks them] → The repo already uses tabs for bash, and implementation verifies with `make -n` on every target.
- [`ARGS` with embedded quotes (e.g. JSON `-e`) relies on shell word-splitting] → Documented with an example in `make help`/README. Complex vars files can be passed as `ARGS="-e @file.json"`.
- [`lint.sh` doesn't check the Makefile] → Acceptable for a ~60-line file. Verification is `make -n` per target in tasks. Extending `lint.sh` can come later.
