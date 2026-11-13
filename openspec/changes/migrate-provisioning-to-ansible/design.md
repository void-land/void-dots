# Design

## Context

- Provisioning today is done by two imperative bash scripts. Each keeps its package lists as a `PACKAGES_LIST` map plus an `ORDERS_LIST` order array, and its steps as `STEP_NAMES` and `STEP_FUNCS` lists paired by index. Before running, each shows a `select_exclusions` picker from `dotfiles/scripts/scripts-lib.sh`.
  - `void-arch-setup` runs as a normal user and calls `sudo` itself.
  - `void-debian-vps-setup` runs as root and asks for the target user, swap size and timezone before it starts.
- `stow.sh` is a hand-rolled linker. `create_link` always runs `ln -sfn` and always prints `src ===> dst`, so its output can't tell a new link from an unchanged one.
- The machine used for development runs `ansible-core` 2.22 on Arch. The targets carry older versions: Debian 12 ships `ansible-core` 2.14, Ubuntu 24.04 ships 2.16, Debian 13 ships 2.19, and Ubuntu 22.04 ships only 2.12, which is too old.
- `ansible-core` by itself has no modules for pacman, AUR, `authorized_key`, `sysctl`, `mount`, `timezone`, `locale_gen` or `modprobe`. All of those live in `community.general` or `ansible.posix`. The same applies to `ansible.builtin.package`: on Arch it hands off to `community.general.pacman`.
- Per project memory, the VPS profiles can't be tested in local containers. Verification is `./lint.sh`, a syntax check, and `--check` runs on the local Arch box. The real VPS runs are left to the user.

## Goals / Non-Goals

**Goals:**
- Use only `ansible-core`, and enforce that in config and in lint, not just by convention.
- Keep roles small and single-purpose, and make the distro-specific parts data or a single dispatch file, so a new profile is mostly variables.
- Keep the current interactive experience: the yay-style exclude picker and asking for inputs up front.
- Write the content so it works on every `ansible-core` from 2.14 to 2.22.

**Non-Goals:**
- KDE settings (`void-kde-setup`, `void-kde-panel`) stay manual and out of scope.
- No new provisioning features beyond what the two scripts do today. One exception: configured SSH keys for the VPS user, which remote mode needs.
- No Fedora or other distros. No Molecule or container test harness.
- No AUR packages that depend on other AUR packages (see Risks).

## Decisions

### D1. Layout: `ansible/` plus a root `bootstrap.sh`

Per CLAUDE.md, the root is for tooling and `dotfiles/` holds the deployable files. Ansible is tooling, so it goes at the root:

```
bootstrap.sh
ansible/
  ansible.cfg
  inventory/             # group_vars/host_vars live here so every playbook dir picks them up
    local.yml            # local-arch, local-debian, local-ubuntu → localhost, connection=local
    hosts.example.yml    # remote template; hosts.yml is git-ignored
    group_vars/
      all.yml            # void_repo_url/branch/dest, void_min_ansible_version
      arch_desktop.yml   # steps, package groups, AUR list, services, DM, locales
      vps.yml            # shared VPS vars (package groups, swap, docker)
      debian_vps.yml     # Debian-only overrides (supported releases)
      ubuntu_vps.yml     # Ubuntu-only overrides
    host_vars/           # git-ignored except README.md
  site.yml               # imports both profile playbooks
  playbooks/
    arch_desktop.yml     # hosts: arch_desktop
    vps.yml              # hosts: vps   (debian_vps + ubuntu_vps)
  library/
    void_pacman.py
    void_aur.py
  module_utils/
    void_common.py       # shared run/parse helpers for the two modules
  roles/
    preflight/ system_update/ packages/ services/ shell/ locale/ timezone/ dotfiles/
    pacman_config/ aur/ display_manager/ gaming/           # Arch-only
    user/ docker/ swap/                                    # VPS-only
```

Each role has `defaults/main.yml`, `tasks/main.yml`, a `handlers/main.yml` where needed, and a `meta/main.yml` (`argument_specs`) for its inputs. The `argument_specs` checks are built into ansible-core and validate role inputs before the role runs.

*Rejected:* putting everything in `dotfiles/ansible/`. `dotfiles/` is what gets stowed, and Ansible isn't a config that gets symlinked.

### D2. Enforcing builtin-only

`ansible.cfg` sets:
- `collections_path = ./collections`, a directory that doesn't exist
- `collections_scan_sys_path = False`
- `library = ./library`, `module_utils = ./module_utils`, `roles_path = ./roles`

With those settings, the bundled `ansible_collections` of a full `ansible` install can't be resolved, while `ansible.builtin` keeps working because it's part of core. All tasks use FQCNs.

`lint.sh` adds a guard that collects every module key in the task, handler and playbook YAML and fails on anything that isn't `ansible.builtin.*`, `void_*`, or a task keyword. It parses the files with the `python3` + `yaml` stack that ansible-core already depends on, not with grep.

Builtin replacements for the missing modules:

| Needed | Approach |
| --- | --- |
| pacman | `void_pacman` (D4) |
| AUR | `void_aur` (D5) |
| `authorized_key` | `ansible.builtin.lineinfile` per key, plus `ansible.builtin.copy remote_src force:false` for root's file |
| `sysctl` | `copy` a `/etc/sysctl.d/99-void.conf` file, and a handler that runs `sysctl --system` |
| `mount` (fstab) | `lineinfile` on `/etc/fstab` |
| `timezone` | read with `timedatectl show -p Timezone --value` (`changed_when: false`, `check_mode: false`), then set only if different |
| `locale_gen` | `lineinfile` on `/etc/locale.gen`, and a handler that runs `locale-gen` |
| `modprobe` | `copy` a `/etc/modules-load.d/ntsync.conf` file; `command modprobe` only when `/sys/module/ntsync` is missing |
| apt, systemd, user, group, git | the builtins `apt`, `systemd_service`, `user`, `group`, `git` |

A Python module is written only when no combination of builtins can be both idempotent and safe in check mode. That applies to package management, so only `void_pacman` and `void_aur` are modules.

### D3. Profiles, inventory and variables

- The local inventory has three hosts, each in its own profile group: `local-arch`, `local-debian` and `local-ubuntu`, all with `ansible_connection: local`. The bootstrap runs `-i inventory/local.yml -l local-<distro>`. This keeps the inventory static and avoids generating one at runtime.
- The remote inventory has `debian_vps` and `ubuntu_vps` as children of `vps`. Connection details and secrets go in `host_vars/<host>.yml`, which can be encrypted with `ansible-vault` (part of core).
- Variable names follow ansible-lint's naming rules:
  - Cross-role globals start with `void_`: `void_target_user`, `void_repo_url`, `void_repo_branch`, `void_repo_dest`, `void_profile_steps`.
  - Role variables start with the role name: `packages_groups`, `packages_exclude_groups`, `aur_packages`, `aur_exclude`, `swap_size`, `docker_daemon_json`, and so on.
- Package groups are an ordered YAML list such as `- {name: gaming, packages: [...]}`. YAML lists keep their order, so the bash order array isn't needed and there's nothing to keep in sync.
- `void_profile_steps`, a list of `{id, desc}`, describes each profile's steps for the bootstrap picker. Playbooks list their roles statically, each tagged with its step id: `roles: [{role: docker, tags: [docker]}]`. `preflight` has `tags: [always]`.

  Keeping the roles static means tags behave predictably and ansible-lint can follow the roles. The cost is that the step list exists twice. `lint.sh` closes that gap by comparing `ansible-playbook --list-tags` against `void_profile_steps` for each profile.

  *Rejected:* building the role list in the playbook by looping `include_role` over `void_profile_steps`. Tags on dynamic includes need `apply:` boilerplate, and they break `--list-tags`.

### D4. `void_pacman` module

- Parameters:
  - `name` (list)
  - `state`: `present`, `absent` or `latest`
  - `update_cache` (bool)
  - `upgrade` (bool)
  - `extra_args`
- Present: runs `pacman -T <names>` to find missing packages. `-T` prints only the names it can't satisfy and counts provides as satisfying. It then runs `pacman -S --needed --noconfirm <missing>`. Pacman groups are not supported as names, and no current list uses one.
- Upgrade: runs `pacman -Qu` after a sync. It reports changed only if that list is non-empty, then runs `pacman -Su --noconfirm`.
- Unknown names are found with `pacman -Sp --print-format %n` and cause a failure that names them.
- Check mode reports what would happen and stops before any transaction.
- Returns `packages` (the affected names) and `stdout`.
- Runs as root through the play's `become`.

### D5. `void_aur` module: makepkg without a helper

- Parameters:
  - `name` (list)
  - `build_user` (required, non-root)
  - `build_dir` (default `~build_user/.cache/void-dots/aur`)
  - `state`: `present`
- Runs as root. For each package not installed (`pacman -Q`):
  1. Query the AUR RPC v5 `info` endpoint with `urllib`. That shows whether the package exists and returns its `Depends` and `MakeDepends`.
  2. Install those dependencies from the repos with `pacman -S --needed --asdeps`.
  3. Clone or pull `https://aur.archlinux.org/<pkg>.git` as the build user (`runuser -u <user> --`).
  4. Run `makepkg -f --noconfirm --cleanbuild` as the build user.
  5. Run `pacman -U --needed --noconfirm` on the resulting `*.pkg.tar.zst`, as root.
- A dependency that isn't in the repos fails with a clear "AUR dependency not supported" message.
- Check mode stops after the RPC lookup.
- `yay` is installed this way as a normal list entry, so it stays available for interactive use. (`yay-bin` would conflict with an existing source-built `yay`.)

*Rejected:* bootstrapping yay and running `yay -S` as the user. yay calls `sudo` itself mid-run, which means either a password prompt Ansible can't answer or a temporary NOPASSWD sudoers drop-in. Both are fragile and a security smell.

*Rejected:* `makepkg -si`, for the same reason. It runs sudo inside makepkg.

### D6. Privilege model

- Plays set `become: true`. User-scoped tasks set `become_user: "{{ void_target_user }}"`: the git clone, `stow.sh`, and the build steps inside `void_aur`, which use `runuser` instead.
- `pipelining = True` in `ansible.cfg` speeds runs up and avoids the problem of writing temp files when becoming an unprivileged user.
- `acl` is added to the VPS `base` group anyway, as a backstop for modules that transfer files.
- Arch: the bootstrap passes `--ask-become-pass` and runs as the invoking user, and `void_target_user` defaults to `ansible_user_id`.
- VPS run locally as root: no become password is needed.
- Remote: `ansible_user` is root, or a sudo user with `ansible_become_password` in vaulted host_vars.

### D7. Check-mode and idempotency patterns

- Read-only probes (`apt-cache policy`, `timedatectl show`, `swapon --show`, kernel config greps) use `changed_when: false` and `check_mode: false`, so they also run in dry mode.
- A task that depends on something an earlier step only *would have* created guards itself with `when: not ansible_check_mode or <artifact exists>`. Examples: the `docker` group before `docker.io` is installed, and fish before the packages step runs. With that guard, `--check` on a fresh box succeeds.
- Every state change is in a handler or has a precise `changed_when`: database refresh after `pacman.conf` edits, `locale-gen`, `sysctl --system`, the Docker restart after `daemon.json`.
- Conditionals always evaluate to real booleans (`| bool`, `| length > 0`), because ansible-core 2.19's templating rejects non-boolean conditionals.

### D8. User services and the display manager

- User services are enabled with `ansible.builtin.systemd_service: scope=global, enabled=true`. That writes the symlinks for every user without needing a user bus or `XDG_RUNTIME_DIR`, so it also works over SSH and from a TTY. The units start at the next login.
- Conflicting display managers are disabled with `enabled: false` but are **not** stopped. The old script ran `disable --now`, which killed the running Plasma session in the middle of the run. emptty is enabled and takes over at the next boot. The final message from the bootstrap already says a reboot is needed.

### D9. Password handling for new VPS users

- The bootstrap reads the password twice with `read -rs` and pipes it to `openssl passwd -6 -stdin`.
- It writes `{"user_password_hash": "..."}` to a file created with `mktemp` under `umask 077`. It removes the file in an `EXIT`/`INT`/`TERM` trap, and passes it as `-e @file`. The hash is never on argv.
- The `user` role uses `ansible.builtin.user: password=<hash>, update_password=on_create` with `no_log: true`.
- Remote runs put the hash in vaulted `host_vars`.

*Rejected:* `vars_prompt` with `encrypt:`. It needs passlib on Python 3.13 or newer, which breaks on fresh Arch and Debian 13.

### D10. Dotfiles role and the `stow.sh` change

- `create_link` gains an early return when `[[ -L $target && $(readlink "$target") == "$source" ]]`. Lines printed for creating, backing up and pruning links keep their current text.
- The role:
  1. Probes the clone: does it exist, and is it dirty (`git status --porcelain`)?
  2. Clones with `ansible.builtin.git` when the clone is missing. An existing clone is updated only with `git pull --ff-only`, as the target user, when it's clean and on the configured branch. The git module isn't used for updates, because its update path resets the work tree and could drop unpushed local commits.
  3. Runs `stow.sh -s`, or `-n -s` in check mode, as the target user, with `chdir` set to the clone.
- `changed_when` matches ` ===> |Backing up |Pruned dangling` in stdout. The leading space keeps it from matching the `======>` section log lines.
- On Arch, where the clone used by the bootstrap and the target user's clone are usually the same `~/.void-dots`, the role only re-checks it.

### D11. Bootstrap flow

The script runs these steps in order:

1. Parse flags with `getopts`: `-p profile`, `-y`, `-t tags`, `-x skip`, `-n`, `-e var=val` (repeatable), `-d dest`, `-b branch`, `-u user`, `-h`, and `--` passthrough.
2. Detect the distro from `ID` and `ID_LIKE` in `/etc/os-release`.
3. Check privileges.
4. Install prerequisites:
   - pacman: `git`, `python`, `ansible-core`, `openssl`
   - apt: `git`, `python3`, `python3-venv`, `ansible-core`, `openssl`
   - Compare the distro version against `void_min_ansible_version` (2.14). If it's too old, create `~/.local/share/void-dots/ansible-venv` and `pip install 'ansible-core>=2.17,<2.18'`. That version still supports a Python 3.10 controller, which Ubuntu 22.04 has.
5. Clone the repo, or fast-forward it with `git pull --ff-only` and warn if that fails.
6. Source `dotfiles/scripts/scripts-lib.sh` from the clone, so the bootstrap reuses `select_exclusions` instead of copying it.
7. Read `void_profile_steps` and `packages_groups` through `ansible-inventory -i inventory/local.yml --host local-<x>`, extracting them with a short `python3 -c` JSON snippet. `jq` isn't guaranteed to be on a fresh VPS.
8. Show the step picker. If `packages` stays selected, show the group picker too. Then ask for any inputs the selected steps need.
9. `exec` `ansible-playbook` with `ANSIBLE_CONFIG` set to the repo's `ansible.cfg`, plus `--skip-tags`, `-e packages_exclude_groups=[...]` as JSON, and the user's own arguments.
10. Report the playbook's exit code.

Inside the bootstrap, all user-facing logging uses the `info`, `warn` and `die` style from `scripts-lib.sh`. Before the clone exists, the bootstrap needs minimal inline copies of those helpers, because it can't source anything until then.

### D12. Ansible output and logs

- `ansible.cfg` sets `callback_result_format = yaml`, `display_skipped_hosts = False`, `retry_files_enabled = False`, `interpreter_python = auto_silent`. The log goes to `~/.cache/void-dots/ansible.log`: `bootstrap.sh` creates that directory and sets `ANSIBLE_LOG_PATH`, so manual runs without it get no "log not writeable" warning.
- Secret-bearing tasks use `no_log: true`.

## Risks / Trade-offs

- [`curl | bash` runs whatever is on `main`] → The bootstrap prints the commit it's about to run. The README also documents the safer path: clone, then `./bootstrap.sh`.
- [The AUR RPC or `aur.archlinux.org` is unreachable, which is common on restricted networks] → `void_aur` fails per package with the URL it tried, and `-x aur` skips the step. The error message suggests a proxy setting through `-e`.
- [AUR packages with AUR-only dependencies aren't supported] → None of the current list needs one. The failure is explicit, and recursive resolution can be added later inside the module without changing the spec.
- [Content has to work on both ansible-core 2.14 and 2.22, and 2.19 changed templating] → Use only modules and keywords available in 2.14 and strict boolean conditionals. Syntax-check on the local 2.22, and give the user a `--check` run for a Debian 12 VPS.
- [The step list exists twice, in the playbook and in `void_profile_steps`] → `lint.sh` checks the two match.
- [Disabling a display manager without stopping it means emptty isn't running until reboot] → This is on purpose, so the session isn't killed. The final message calls it out.
- [Removing the scripts breaks muscle memory and any notes that use their flags] → The README gets a mapping table from each old flag to its `bootstrap.sh -t <step>` equivalent.
- [The venv fallback downloads from PyPI] → The version range is pinned and the venv is only used when the distro package is too old, which today means only Ubuntu 22.04.

## Migration Plan

1. Build `ansible/`, `bootstrap.sh`, the `stow.sh` tweak and the `lint.sh` additions while the old scripts still exist.
2. Verify locally on Arch:
   - `./lint.sh`
   - `ansible-playbook --syntax-check`
   - `bootstrap.sh -n`, a check-mode run of `arch_desktop`
   - a real `-t pacman_config,locale,dotfiles` run, then a second run that must show `changed=0`
3. Hand off VPS verification to the user: a Debian 12 and an Ubuntu 24.04 VPS, both locally through curl and remotely from the laptop.
4. Once the user confirms, delete `void-arch-setup` and `void-debian-vps-setup` and update README.md, CLAUDE.md and the `scripts-lib.sh` comment, in the same change.
5. Rollback: `git revert` the change. The old scripts come back from history unchanged, and `stow.sh`'s skip-if-correct change is compatible with them.
