# Proposal

## Why

The day-to-day commands for this repo are spread across `stow.sh` flags, `lint.sh`, and long `ansible-playbook` lines that need `ANSIBLE_CONFIG`, the right inventory, the right `-l` host and the right playbook (see the README "Run locally" and "Push to a VPS" blocks). A root `Makefile` gives each of them a short, discoverable name (`make stow`, `make arch`, `make vps HOST=…`), the same way the Taskfile the user referenced does, without adding a new tool dependency (`make` is already on every target distro).

## What Changes

- Add a root `Makefile` whose default target (`make` / `make help`) lists every target with a one-line description.
- Linking targets that wrap `stow.sh`: `stow` (`-s`), `unstow` (`-u`), `restow` (`-u` then `-s`), each honouring a `DRY=1` variable that adds `-n`.
- Lint targets that wrap `lint.sh`: `lint` and `lint-fix` (`-w`).
- Local Ansible profile targets that call `ansible-playbook` directly against `inventory/local.yml`: `arch` (`local-arch`, `playbooks/arch_desktop.yml`), `debian` (`local-debian`) and `ubuntu` (`local-ubuntu`) (both `playbooks/vps.yml`). They set `ANSIBLE_CONFIG` to the repo's `ansible/ansible.cfg` so the builtin-only policy always applies.
- A remote target, `vps HOST=<inventory host>`, that pushes `playbooks/vps.yml` through the git-ignored `inventory/hosts.yml`, failing with a clear message when `HOST` is unset or `hosts.yml` is missing.
- Shared make variables for all Ansible targets: `CHECK=1` (`--check`), `TAGS=` (`--tags`), `SKIP=` (`--skip-tags`), `TARGET_USER=` (`-e void_target_user=`), and `ARGS=` (passed through verbatim, e.g. `ARGS="-e swap_size=4G --ask-vault-pass"`).
- Document the Makefile in `README.md` and `CLAUDE.md` (repo root tooling list and command sections).
- Out of scope: Docker build/run targets and a Dockerfile (no container setup exists in the repo; can be a later change), and a `make bootstrap` wrapper (the Makefile assumes ansible-core is already installed; `bootstrap.sh` stays the first-run entry point).

## Capabilities

### New Capabilities
- `task-runner`: The root `Makefile` as the short-name entry point for linking dotfiles, linting, and running the Ansible profiles locally or against a remote VPS, including its variables and help output.

### Modified Capabilities
<!-- None: stow.sh, lint.sh, bootstrap.sh and the Ansible profiles keep their existing behaviour; the Makefile only invokes them. -->

## Impact

- New file: `Makefile` at the repo root (tab-indented, as make requires).
- Docs: `README.md` (structure note about root tooling, new "Makefile" section), `CLAUDE.md` (root tooling list and Commands block).
- No changes to `stow.sh`, `lint.sh`, `bootstrap.sh`, or anything under `ansible/` or `dotfiles/`.
- Runtime dependency: GNU make (already present on Arch; `build-essential`/`make` on Debian/Ubuntu). Ansible targets require `ansible-playbook` on `PATH`.
