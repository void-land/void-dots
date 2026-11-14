# Tasks

## 1. Makefile skeleton and help

- [x] 1.1 Create the root `Makefile` (tab-indented, GNU make) with `REPO := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))`, `.DEFAULT_GOAL := help`, `.PHONY` for every target, and a `help` target that prints each `target: ## description` line plus a variables block (`DRY`, `CHECK`, `TAGS`, `SKIP`, `TARGET_USER`, `HOST`, `BECOME`, `ARGS`, with an `ARGS` example). Verify that `make` and `make -C /tmp -f ~/.void-dots/Makefile` both print the same list and change nothing.

## 2. Linking and lint targets

- [x] 2.1 Add `stow`, `unstow` and `restow` (two recipe lines: `-u` then `-s`) calling `$(REPO)/stow.sh`, with `DRY=1` (also `yes`/`true`) adding `-n` to every call. Verify with `make -n restow DRY=1` that it prints `stow.sh -n -u` then `stow.sh -n -s`. Verify that `make stow DRY=1` runs a real dry run and leaves `~` unchanged. Verify that `make stow` on an already-linked machine prints no `===>`/`Backing up`/`Pruned` lines.
- [x] 2.2 Add `lint` (`$(REPO)/lint.sh`) and `lint-fix` (`lint.sh -w`). Verify that `make lint` passes, and that its exit status matches `./lint.sh` (`make lint; echo $?`).

## 3. Ansible targets

- [x] 3.1 Add `ANSIBLE_CONFIG := $(REPO)/ansible/ansible.cfg`, passed inline to every `ansible-playbook` call. Add the shared option tail (`CHECK` via `filter 1 yes true`, `TAGS`, `SKIP`, `TARGET_USER` → `-e void_target_user=…`, then `ARGS`) and `BECOME ?= $(if $(filter 0,$(shell id -u)),,-K)`. Verify with `make -n arch CHECK=0` that there is no `--check`. Verify with `make -n arch CHECK=1 TAGS=aur,gaming SKIP=display_manager ARGS='-e swap_size=4G'` that the options appear in that order. Verify with `ANSIBLE_CONFIG=/nope make -n arch` that the repo's config path is shown.
- [x] 3.2 Add the local profile targets `arch` (`-l local-arch playbooks/arch_desktop.yml`), `debian` (`-l local-debian playbooks/vps.yml`) and `ubuntu` (`-l local-ubuntu playbooks/vps.yml`), each running `cd $(REPO)/ansible && ansible-playbook -i inventory/local.yml … $(BECOME) <options>`. Verify with `make arch CHECK=1 BECOME= ARGS='-e ansible_become=false'` that the dry run completes without sudo. Verify that `make debian CHECK=1 BECOME= ARGS='-e ansible_become=false -e void_profile=arch_desktop -e preflight_min_release='` without `TARGET_USER` exits non-zero at preflight, and that `echo $?` is non-zero.
- [x] 3.3 Add `vps` using `-i inventory/hosts.yml -l $(HOST) playbooks/vps.yml` with no default `-K`, guarded by a non-help prerequisite that `$(error …)`s when `HOST` is empty and a recipe line that fails with a "copy hosts.example.yml to hosts.yml" message when `ansible/inventory/hosts.yml` is missing. Verify that `make vps` exits non-zero asking for `HOST`, that `make vps HOST=x` without `hosts.yml` exits non-zero with the copy hint, and that `make -n vps HOST=x ARGS=--ask-vault-pass` (with a temporary `hosts.yml` copied from the example, removed afterwards) shows the full command.

## 4. Documentation

- [x] 4.1 Update `README.md`:
  - Add `Makefile` to the repo-root tooling sentence under "Repository Structure".
  - Add a "🛠️ Makefile" section after Quick start with a target/variable table matching `make help`. It notes that `bootstrap.sh` remains the first-run path and that `make` must be installed on minimal Debian/Ubuntu.
  - Add a one-line `make` equivalent in the "Run locally", "Push to a VPS" and `stow.sh` sections.

  Verify that every target and variable in the README table appears in `make help` output, and the reverse.
- [x] 4.2 Update `CLAUDE.md`. Add `Makefile` to the root tooling list in "What this repo is". In "Commands", add `make help`, `make stow`/`restow DRY=1`, `make lint`, `make arch CHECK=1` and `make vps HOST=<host>`, and note that `TARGET_USER` is used instead of `USER`. Verify that the commands listed run as written with `make -n`.

## 5. Integration check

- [x] 5.1 Run `./lint.sh` (unchanged scripts still pass) and `git status`. Verify that only `Makefile`, `README.md` and `CLAUDE.md` changed outside `openspec/`, and that `make help` lists exactly the targets in `specs/task-runner/spec.md`.

## Workflow follow-up

- Real (non-check) runs of `make arch` and `make vps` need sudo or a VPS; hand those to the user after the dry runs pass.
- Archive the change once reviewed.
