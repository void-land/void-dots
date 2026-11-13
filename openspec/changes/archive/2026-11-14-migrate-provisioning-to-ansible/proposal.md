# Proposal

## Why

Two separate bash scripts handle provisioning: `void-arch-setup` for the Arch desktop and `void-debian-vps-setup` for Debian/Ubuntu VPSes. Each keeps its own package lists, prompts and idempotency checks. Neither has a dry run, a way to push a setup to a remote machine, or a single entry point that detects the machine and sets it up end to end. Moving both to an Ansible setup with one `curl | bash` bootstrap gives:

- one declarative, idempotent source of truth per machine profile,
- a real check mode,
- the same playbooks for local runs and for SSH pushes to a VPS.

Ansible offers no setting that forbids collections, and its built-in package interface depends on `community.general` for pacman. Because of that, the setup must stay on `ansible-core` only and be self-contained: no Ansible Galaxy roles or collections.

## What Changes

- Add a self-contained Ansible project under `ansible/`. It contains `ansible.cfg`, inventories, layered `group_vars`, one playbook per profile plus `site.yml`, and reusable roles. It may use only `ansible.builtin.*` modules and its own modules in `ansible/library/`.
- Add three profiles:
  - **arch-desktop**: replaces `void-arch-setup`. Covers the pacman config and multilib, package groups, AUR packages, system and user services, the emptty display manager, the fa_IR locale, Fish, and gaming (GameMode, NTSync).
  - **debian-vps** and **ubuntu-vps**: replace `void-debian-vps-setup`. Cover the update, apt package groups, sudo user and SSH keys, Docker from the distro repos, swap, timezone/NTP, and Fish. They share one role set and differ only in profile variables.
- Write our own Ansible modules where `ansible-core` has no builtin:
  - `void_pacman`: pacman install, upgrade and sync, with check-mode support.
  - `void_aur`: builds and installs AUR packages with `makepkg` as an unprivileged user, so no AUR helper is needed.
- Enforce "builtin only" in `ansible.cfg` (`collections_scan_sys_path = False`, empty `collections_path`). Add a lint guard that rejects any module that is neither `ansible.builtin.*` nor a local `void_*` module.
- Add a `dotfiles` role on every profile. It clones or updates the repo in the target user's home and runs `stow.sh -s` as that user.
- Make `stow.sh` skip links that are already correct. That lets Ansible report `changed` accurately. Its external behaviour does not change.
- Add `bootstrap.sh` at the repo root, runnable as `bash -c "$(curl -fsSL https://raw.githubusercontent.com/void-land/void-dots/main/bootstrap.sh)"`. It:
  - detects the distro,
  - installs `git` and `ansible-core` (from a venv when the distro's version is too old),
  - clones or updates the repo,
  - offers the existing yay-style step and package-group pickers, which become `--skip-tags` and extra vars,
  - runs the matching profile on localhost.
- Allow remote provisioning from the laptop: a git-ignored `ansible/inventory/hosts.yml`, created from a committed `hosts.example.yml`, drives the same VPS playbooks over SSH.
- Extend `lint.sh` with `ansible-playbook --syntax-check`, `py_compile` for the custom modules, the builtin-only guard, and `ansible-lint` when it is installed.
- **BREAKING**: Delete `dotfiles/scripts/void-arch-setup` and `dotfiles/scripts/void-debian-vps-setup`. Their flags go away. Remove them from README and CLAUDE.md and document the bootstrap and per-profile `ansible-playbook` usage instead.

## Capabilities

### New Capabilities

- `provisioning-framework`: layout of the Ansible project and its builtin-only rule. Covers configuration, inventories and profile variable layering, the reusable role contract (tags, check mode, idempotency), the custom `void_*` modules, and lint checks.
- `provisioning-bootstrap`: the one-line `bootstrap.sh` entry point. Covers OS-to-profile detection, Ansible installation, repo clone and update, interactive and non-interactive step selection, and how it calls the playbook.
- `arch-desktop-profile`: what provisioning an Arch/EndeavourOS desktop must achieve, porting `void-arch-setup`.
- `vps-profiles`: what provisioning a Debian or Ubuntu VPS must achieve, locally or over SSH, porting `void-debian-vps-setup`.
- `dotfiles-linking`: getting the repo onto a machine and symlinking it for the target user, including the idempotent `stow.sh` reporting that Ansible depends on.

### Modified Capabilities

None. No specs exist yet under `openspec/specs/`.

## Impact

- **New**:
  - `ansible/` (cfg, inventory, group_vars, playbooks, roles, library)
  - `bootstrap.sh`
- **Modified**:
  - `stow.sh`: skips links that are already correct
  - `lint.sh`: adds the Ansible checks
  - `.gitignore`: `ansible/inventory/hosts.yml`, host_vars secrets
  - `README.md` and `CLAUDE.md`: the commands table, quick start, provisioning sections, and the "ordered profile maps" and "step-picker" notes
  - the `scripts-lib.sh` comment that names `void-arch-setup`
- **Removed**: `dotfiles/scripts/void-arch-setup`, `dotfiles/scripts/void-debian-vps-setup`.
- **Dependencies**:
  - Runtime: `ansible-core` ≥ 2.14 and `python3` on the machine that runs Ansible; `python3` on targets. No Galaxy content.
  - Bootstrap: `curl`, `git`, plus `openssl`, which is used to hash a new VPS user's password.
- **Unchanged**: `void-kde-setup` and `void-kde-panel` stay manual and are not part of any profile. `select_exclusions` in `scripts-lib.sh` stays, because `void-kde-setup` and the bootstrap use it.
