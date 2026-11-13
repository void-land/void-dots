# Tasks

## 1. Ansible project scaffold and builtin-only enforcement

- [x] 1.1 Create `ansible/ansible.cfg` per D2/D6/D12: `collections_path` pointing at a missing dir, `collections_scan_sys_path = False`, `library`, `module_utils`, `roles_path`, `pipelining`, yaml results, `log_path`. Verify that with the full `ansible` package installed, a scratch play calling `community.general.pacman` fails because the module can't be resolved, while `ansible.builtin.ping` succeeds.
- [x] 1.2 Create `inventory/local.yml` with the three hosts `local-arch`, `local-debian` and `local-ubuntu`, each in its profile group and with `debian_vps` and `ubuntu_vps` under `vps`. Also create `inventory/hosts.example.yml`. Add `ansible/inventory/hosts.yml` and `ansible/inventory/host_vars/*` (except README) to `.gitignore`. Verify that `ansible-inventory -i inventory/local.yml --graph` shows the expected tree, and that `git status` ignores a copied `hosts.yml`.
- [x] 1.3 Create `inventory/group_vars/all.yml`, `arch_desktop.yml`, `vps.yml`, `debian_vps.yml` and `ubuntu_vps.yml`. Port the package groups, AUR list, services and DM list from the two scripts as ordered lists, and add `void_profile_steps` for each profile. Verify that `ansible-inventory --host local-ubuntu` shows the merged vars with Ubuntu overrides winning over `vps`.
- [x] 1.4 Create `site.yml` and `playbooks/{arch_desktop,vps}.yml` with static, tagged role lists (empty stub roles for now) and `preflight` tagged `always`. Verify that `ansible-playbook --syntax-check` and `--list-tags` pass for each playbook.
- [x] 1.5 Extend `lint.sh` with:
  - `--syntax-check` of each playbook
  - `python3 -m py_compile` on `library/` and `module_utils/`
  - the YAML-parsed builtin-only module guard
  - the check that `--list-tags` matches `void_profile_steps`
  - `ansible-lint` if it's installed

  Verify that `./lint.sh` passes, and that it fails and names the file when a scratch task uses `community.general.timezone` or a profile step id is removed from the playbook.

## 2. Custom modules

- [x] 2.1 Write `module_utils/void_common.py` with shared command-run and error helpers. Write `library/void_pacman.py` per D4 (present/absent/latest, update_cache, upgrade, check mode, unknown-name failure, `packages` return), with `DOCUMENTATION`/`EXAMPLES`/`RETURN`. Verify with ad-hoc `ansible -m void_pacman`: an installed package reports unchanged, a missing package in `--check` reports changed without installing, and a bogus name fails with its name in the message.
- [x] 2.2 Write `library/void_aur.py` per D5: RPC lookup, repo dependency install, clone and `makepkg` as `build_user` via `runuser`, `pacman -U`, check mode, and clear failures for a missing package, an AUR-only dependency, or the network. Verify locally: `--check` on `vazirmatn-fonts` reports changed, a real run installs it with build files owned by the user, a re-run reports unchanged, and a bogus package fails clearly.

## 3. Shared roles

- [x] 3.1 `preflight` role: assert distro/profile match, supported release (VPS), ansible version ≥ `void_min_ansible_version`, `void_target_user` valid and non-root, timezone exists in zoneinfo, and a new user has a password hash. Verify that `-l local-debian` on the Arch box fails in preflight with the distro message and no other task runs.
- [x] 3.2 `system_update` and `packages` roles, which dispatch by `ansible_os_family` to `void_pacman` or `ansible.builtin.apt` (with `force_confdef`/`force_confold` options) and honour `packages_exclude_groups`. Add `meta/argument_specs.yml` to both. Verify that `--check -t packages -e '{"packages_exclude_groups":["gaming"]}'` on Arch lists no gaming packages.
- [x] 3.3 `services` role: system services enabled and started, user services enabled with `scope: global` (D8). Verify that after running on Arch, `systemctl --global is-enabled pipewire.service` reports enabled, and a re-run is `changed=0`.
- [x] 3.4 `shell`, `locale` and `timezone` roles, using builtins plus handlers per D2/D7. Verify on Arch that `-t locale,shell` is idempotent (second run `changed=0`), and that `--check -t timezone -e timezone_name=UTC` makes no change.
- [x] 3.5 `dotfiles` role per D10 (probe the clone, conditionally update with git, run `stow.sh` as the target user, `-n` in check mode, regex `changed_when`). Verify on Arch that `-t dotfiles` reports `changed=0` on an already-stowed machine and that a dirty clone produces the warning and is left alone.

## 4. stow.sh idempotent reporting

- [x] 4.1 Make `create_link` return early with no output when the target is already a symlink to the source. Update the README `stow.sh` section to say unchanged links are skipped silently. Verify that a second `./stow.sh -s` prints no `===>`, `Backing up` or `Pruned` lines, that a deliberately wrong `~/.config/fish` symlink is replaced and printed, and that `./stow.sh -n -s` and `-u` behave as before.

## 5. Arch desktop profile roles

- [x] 5.1 `pacman_config` role: ParallelDownloads, Color, multilib uncomment, and a refresh handler. Verify on a copy of `pacman.conf` (via a scratch var for the path) that multilib gets enabled and a re-run reports no change.
- [x] 5.2 `aur` role: wrap `void_aur` with `aur_packages` minus `aur_exclude`, and add `yay` to the list. Verify that `--check -t aur` lists only the missing, non-excluded packages.
- [x] 5.3 `display_manager` role: disable without stopping the conflicting DMs, enable emptty (D8). Verify that `--check -t display_manager` on the live Plasma box reports the planned changes and the session stays up.
- [x] 5.4 `gaming` role: gamemode group (fail clearly if the group is missing, skip under check mode if the package isn't installed), NTSync kernel version and kconfig detection, `modules-load.d` file, and conditional modprobe. Verify on the 6.18 kernel that `-t gaming` loads ntsync and a re-run is `changed=0`.
- [x] 5.5 Wire all Arch roles into `playbooks/arch_desktop.yml` in spec order and integration-test: run `--check` for the whole profile on the local Arch box, then a real run, then a second run. Record that the second run shows `changed=0`, ignoring any upstream updates.

## 6. VPS profile roles

- [x] 6.1 `user` role: create the user with `update_password: on_create` and `no_log`, add to the sudo group, install configured keys with `lineinfile`, otherwise copy root's keys with `force: false`, and enforce modes. Verify that `--syntax-check` and `ansible-lint` are clean and `--check` against `local-debian` fails only at the distro preflight on Arch. Real verification happens in 6.5.
- [x] 6.2 `docker` role: candidate probes with `apt-cache policy` (`check_mode: false`), package list selection per distro, `daemon.json` with `force: false` and a restart handler, services, and docker group with a check-mode guard. Verify with syntax and lint clean. Real verification happens in 6.5.
- [x] 6.3 `swap` role: skip if swap is active, `fallocate` with `dd` fallback, `mkswap`, `swapon` with cleanup on failure, fstab `lineinfile`, and the sysctl drop-in. Verify with syntax and lint clean. Real verification happens in 6.5.
- [x] 6.4 Wire the VPS roles into `playbooks/vps.yml` in spec order. Document remote usage (copy `hosts.example.yml`, set `ansible_user`, vault the password hash and become password) in a README "Ansible provisioning" section. Verify that the documented `ansible-playbook -i inventory/hosts.yml playbooks/vps.yml --list-tasks` command runs as written.
- [x] 6.5 Hand off to the user (per project memory there's no local container testing): give them the exact commands for a Debian 12 and an Ubuntu 24.04 VPS, both by bootstrap on the box and by push from the laptop, and the expected checks: `docker compose version`, `swapon --show`, `getent group sudo docker`, the fish login shell, the stowed `~/.config/fish`, and a second run with `changed=0`. Wait for their confirmation before group 8.

## 7. Bootstrap script

- [x] 7.1 Write `bootstrap.sh` per D11:
  - flags and `-h` usage
  - minimal inline helpers that run before the clone exists
  - distro detection and privilege checks
  - prerequisite and ansible-core install, with the venv fallback and version comparison
  - clone or `--ff-only` update with a warning on failure, and printing the commit that will run

  Verify that `./bootstrap.sh -h` exits 0, `-p fedora` and an unsupported `ID` fail before any install, and running as root on Arch is refused.
- [x] 7.2 Add the picker flow: source `scripts-lib.sh`, read `void_profile_steps`/`packages_groups` through `ansible-inventory` + `python3`, show the step and group pickers, collect inputs up front (target user, swap size, timezone, and a password hashed with `openssl passwd -6` into a `umask 077` mktemp file with a trap cleanup), and translate everything into `--skip-tags`/`-e`. Verify on Arch: excluding steps in the picker yields the matching `--skip-tags` (print the final command with `-n`), and no temp file is left behind after Ctrl-C at the password prompt.
- [x] 7.3 Add `-y`/`-t`/`-x`/`-n`/`-e`/`--` passthrough and exit-code propagation, plus the final success and re-login message. Verify that `./bootstrap.sh -y -n` on Arch runs check mode with no prompts, and a forced failing `-e` (e.g. invalid `void_target_user=root`) exits non-zero without the success message.
- [x] 7.4 Rewrite the README quick start and "Why this repo?" bullets around the curl one-liner and `./bootstrap.sh`, including the safer clone-first path and a table that maps old script flags to `bootstrap.sh -t <step>`. Verify that each documented command runs as written on the Arch box (`-n` where it would make changes).

## 8. Remove the legacy scripts and finish the docs

- [x] 8.1 After 6.5 is confirmed, delete `dotfiles/scripts/void-arch-setup` and `dotfiles/scripts/void-debian-vps-setup`. Remove their README sections, and update the comment in `scripts-lib.sh` that names `void-arch-setup`. Verify that `grep -rn "void-arch-setup\|void-debian-vps-setup"` outside `openspec/` and `.git/` returns nothing.
- [x] 8.2 Update CLAUDE.md:
  - the commands block, with `bootstrap.sh` and the per-profile `ansible-playbook` usage
  - a new "Ansible provisioning" section covering the builtin-only rule, the `void_*` modules, the profile/vars layering, and the steps that are duplicated between `void_profile_steps` and the playbook's tagged roles
  - the "ordered profile maps" note, replaced with the ordered YAML lists
  - the step-picker note, narrowed to `void-kde-setup` and `bootstrap.sh`

  Verify that the file has no stale references (same grep as 8.1) and that `./lint.sh` passes.

## Workflow follow-up

- Archive the change once the user has confirmed the VPS runs (6.5) and the legacy scripts are removed (8.1).
- After archiving, check that `openspec/specs/` contains the five new capability specs.
