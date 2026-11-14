# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal dotfiles repo for Arch/EndeavourOS + KDE Plasma. There is no build, no test suite, and no package manager — the "product" is a tree of config files plus bash/fish scripts that get symlinked into `$HOME`. The root holds only tooling (`Makefile`, `bootstrap.sh`, `stow.sh`, `lint.sh`, `ansible/`) and docs; everything deployable lives under `dotfiles/` (`apps/`, `shell/`, `editors/`, `kde/`, `home/`, `scripts/`). Verification means running `./lint.sh`, re-running the linker, and `--check` runs of the Ansible profiles, not running tests.

## Commands

```bash
make help             # Makefile: thin wrappers over the commands below
make stow             # stow.sh -s; also unstow, restow (-u then -s); DRY=1 adds -n
make lint             # lint.sh; lint-fix = lint.sh -w
make arch CHECK=1     # local profile (arch|debian|ubuntu); TAGS= SKIP= TARGET_USER= ARGS= BECOME=
make vps HOST=<host>  # playbooks/vps.yml via inventory/hosts.yml; fails early without HOST or hosts.yml

./stow.sh -s          # symlink everything into ~ and ~/.config
./stow.sh -u          # remove those symlinks (only ones pointing back into the repo)
./stow.sh -n -s       # dry run
./lint.sh             # bash -n + shfmt + shellcheck (if installed) + fish --no-execute; -w applies shfmt
./bootstrap.sh -h     # provisioning entry point: detects distro, installs ansible-core, runs the profile
./bootstrap.sh -n     # dry run (--check) with step/package-group pickers; -y unattended, -t/-x steps, -u user, -e vars, -- passthrough

# Ansible by hand (from ansible/; ANSIBLE_CONFIG is required for the builtin-only policy)
export ANSIBLE_CONFIG=$PWD/ansible.cfg
ansible-playbook -i inventory/local.yml -l local-arch playbooks/arch_desktop.yml -K --check
ansible-playbook -i inventory/hosts.yml playbooks/vps.yml -l <host>     # push to a VPS (hosts.yml is git-ignored)

dotfiles/apps/alacritty/themes.sh       # re-pull alacritty themes from upstream
```

The Makefile resolves the repo from its own path and passes `ANSIBLE_CONFIG` inline on every `ansible-playbook` call, so an exported `ANSIBLE_CONFIG` can't bypass the builtin-only policy. The target-user variable is `TARGET_USER`, not `USER`: `USER` is always in the environment and would silently become `void_target_user`. When adding a target, give it a `## description` comment (that's what `make help` lists), add it to `.PHONY` and to README's Makefile table.

## How stowing works (read before adding files)

`stow.sh` is hand-rolled, not GNU stow, and resolves the repo from its own path. `create_links` symlinks each **direct child** of a source dir into the target; a pre-existing real file/dir at a target is moved to `<name>.bak.<timestamp>`:

| Source | Target | Effect |
| --- | --- | --- |
| `dotfiles/home/*` | `~/` | `~/.vpn`, `~/.ucu` are symlinked dirs |
| `dotfiles/scripts` | `~/.scripts` | linked as one dir (`create_link`, singular) |
| `dotfiles/apps/*` | `~/.config/` | `~/.config/alacritty`, `~/.config/mpv`, … |
| `dotfiles/shell/*` | `~/.config/` | `~/.config/fish`, `~/.config/tmux`, `~/.config/bash`, … |
| `dotfiles/editors/zed` | `~/.config/zed` | linked as one dir (`create_link`, singular) |
| `dotfiles/editors/vscode/configs/*` | `~/.config/VSCodium/User/` and `~/.config/Code - OSS/User/` | per-child, looped over `VSCODE_TARGET_DIRS` |

Consequences:
- Adding a file **inside** an already-linked dir needs nothing — the dir itself is the symlink.
- Adding a **new dir directly under a stowed category** (e.g. `dotfiles/apps/foo/`) requires re-running `./stow.sh -s`.
- `stow.sh -s` first prunes symlinks under `~` and `~/.config` that point into the repo at files that no longer exist, so removing a tracked file from the repo cleans up after a pull.
- Adding a **new category** under `dotfiles/` needs a source var + `create_link(s)`/`delete_link(s)` calls in `stow.sh`.
- `dotfiles/editors/vim` is *not* stowed by any code path; `dotfiles/shell/bash/.bashrc` lands at `~/.config/bash/.bashrc`, not `~/.bashrc`. Both are deliberate-looking gaps — don't "fix" them silently.

## KDE settings are applied, not stowed

KDE rewrites its rc files during normal desktop use and fills them with per-install IDs, so nothing under `~/.config/*rc` is symlinked. Instead:

- `dotfiles/kde/settings.conf` is the single source of truth. It is sourced bash (`# shellcheck shell=bash`), with ordered arrays: `KDE_CONFIG` (`file|group|key|value`, `/` nests groups), `KDE_SHORTCUTS` (`component|action|keys`, `\t` separates alternate keys, only non-default bindings), `KDE_DESKTOPS`, `KWIN_EFFECTS_ENABLE`/`_DISABLE`, `KDE_MIME_DEFAULTS`, `KDE_SESSION_ENV`, `EOS_*`, and the `PANEL_*` block.
- `dotfiles/scripts/void-kde-setup` applies it with `kwriteconfig6 --notify`. KWin is reloaded over D-Bus with `busctl --user` (`/KWin reconfigure`, `/Effects loadEffect`, `/VirtualDesktopManager`). Its steps live in `STEP_NAMES` (ids for `-o`) + `STEP_DESCS` (picker labels) + `STEP_FUNCS`, all paired by index. `-c` diffs the live desktop against `settings.conf`, and it is the replacement for watching `git diff` on rc files. It is run manually; `stow.sh` does not call it.
- `dotfiles/scripts/void-kde-panel` (the panel step) uses Plasma's `evaluateScript`, because `plasmashellrc` and `plasma-org.kde.plasma.desktop-appletsrc` key everything by panel/applet ID. It reads `PANEL_*` from `settings.conf`.
- Shortcuts and session env apply only at the next login. kglobalaccel runs inside `kwin_wayland` and has no reload call, so don't "fix" this by restarting services.
- Deliberately not tracked: `[Tiling]` (desktop × screen UUIDs), desktop `Id_N`, colour-scheme blocks in `kdeglobals` (regenerated by `plasma-apply-colorscheme`), and default shortcuts. The theme step avoids `plasma-apply-lookandfeel` because it can reset the panel layout.

## Recurring code patterns

**Ordered profile maps.** Bash associative arrays are unordered, so scripts that present menus keep an explicit order array alongside the map. When adding an entry, update **both**:
- `dotfiles/scripts/void-dns-changer` and `void-dnsproxy-changer`: `DNS_SERVERS`/`DNS_PROFILES` + `DNS_PROFILE_ORDER` (all three scripts)
- `dotfiles/scripts/void-arch-zram`: `ZRAM_PROFILES` + `ZRAM_PROFILE_DESC` + `ZRAM_PROFILE_ORDER`.
- Ansible profiles need no order arrays: package groups are ordered YAML lists (`packages_groups: [{name, packages}]`). But each profile's `void_profile_steps` (in `ansible/inventory/group_vars/`) must list the same step ids, in the same order, as the tagged roles in its playbook (`./lint.sh` checks).

**Library + thin wrapper.** Shared logic lives in a `*-lib.sh` that refuses to run when executed directly (`BASH_SOURCE[0] == $0` guard); callers source it, set config variables, then call one entry point:
- `dotfiles/home/.vpn/ovpn-lib.sh` ← `eliteping-ovpn`, `vpnbaz-ovpn` set `VPN_CONFIG_DIR`/`VPN_AUTH_FILE`/`VPN_EXTRA_ARGS`, then `vpn_connect_interactive`.
- `dotfiles/home/.vpn/openconnect-lib.sh` ← `vpnbaz-openconnect`, `openconnect-connect.sh` set `VPN_SERVERS`/`VPN_AUTH_FILE`/`VPN_EXTRA_ARGS`, then `vpn_connect_interactive`.
- `dotfiles/home/.ucu/ucu-launcher-lib.sh` ← per-game scripts (see `ucu-example`) set `GAME_*`/`WINE_PREFIX`/`PROTONPATH`, define an `umu_env_hook` for Proton env vars, then call `umu_launch_game`.

**Script conventions in `dotfiles/scripts/`:** executables are named `void-<name>` (the sourced `scripts-lib.sh` is not prefixed); `info`/`success`/`warn`/`die` helpers, `require_root` that re-execs via `exec sudo bash "$0" "$@"`, a `usage()` heredoc, `getopts` main, and box-drawing `# ─────` section separators. Interactive by default with non-interactive flags (`-p <profile>`, `-l`). These scripts are on `PATH` via `fish_add_path $HOME/.scripts` and `$HOME/.vpn` in `dotfiles/shell/fish/_env.fish`. Scripts that need repo files outside `dotfiles/scripts/` resolve their own dir with `readlink -f "${BASH_SOURCE[0]}"`, because they're usually invoked through the `~/.scripts` symlink.

**Step-picker prompting model** (`bootstrap.sh`, `void-kde-setup`): one up-front `select_exclusions` picker (yay-style, accepts `1 2 3`, `1-3`, `^4`) rather than per-step yes/no. It lives in `scripts-lib.sh`; it uses bash namerefs for input/output arrays so nested calls can't clobber each other. `bootstrap.sh` sources it from the clone, turns step exclusions into `--skip-tags` and package-group exclusions into `packages_exclude_groups`, asks for every input before the run, and skips pickers with `-y`, `-t`/`-x`, or a non-TTY stdin. `void-kde-setup` skips the picker with `-o`/`-y` or when stdin isn't a TTY.

## Ansible provisioning (`ansible/`)

`bootstrap.sh` (root) replaces the old `void-arch-setup`/`void-debian-vps-setup` scripts. Profiles are inventory groups: `arch_desktop`, and `debian_vps` + `ubuntu_vps` (children of `vps`, sharing `playbooks/vps.yml`). Each step is one role tagged with its step id; `preflight` is tagged `always`.

- **Builtin-only, enforced.** Use only `ansible.builtin.*` (FQCN) or the repo's own modules: `library/void_pacman.py` (pacman) and `library/void_aur.py` (makepkg as the target user via `runuser`, then `pacman -U`; no yay or sudo during the build). Shared helpers live in `module_utils/void_common.py`. `ansible.cfg` sets `collections_scan_sys_path = False` and points `collections_path` at a directory that doesn't exist. `ansible/tools/lint_ansible.py` (run by `lint.sh`) rejects any other module, `collections:`, and `requirements.yml`. When a builtin is missing (sysctl, timezone, authorized_key, mount, modprobe), compose builtins (`lineinfile`, `copy`, `command` with handlers) before writing a new `void_*` module.
- **Variables.** `inventory/group_vars/` is next to the inventory, so every playbook dir loads it: `all` < `vps` < `debian_vps`/`ubuntu_vps`, plus `arch_desktop`. `host_vars/` is git-ignored apart from its README. Globals use the `void_` prefix (`void_target_user`, `void_repo_*`, `void_profile_steps`); role vars use the role name as prefix. Debian/Ubuntu must not override `void_profile_steps`.
- **Role contract.** Idempotent: a second run is `changed=0`. Check-mode safe: read-only probes use `changed_when: false` and `check_mode: false`; tasks that depend on something an earlier step would create are guarded with `not ansible_check_mode or <exists>`. Use `ansible_facts[...]`, not injected `ansible_*` fact vars, and real boolean conditionals (ansible-core 2.19+ is strict). Secrets get `no_log: true`. Content must work on ansible-core 2.14 through 2.22.
- **`dotfiles` role** runs `stow.sh` as the target user and detects changes from ` ===> `/`Backing up `/`Pruned dangling` lines. So `stow.sh` must stay silent for links that are already correct. Existing clones are only updated with `git pull --ff-only`, never with `ansible.builtin.git` (its update path can reset away local commits).
- **Testing without sudo:** `-e ansible_become=false --check`. VPS roles can run on the Arch box with `-l local-debian -e void_profile=arch_desktop -e preflight_min_release=`.

## Fish configuration structure

`dotfiles/shell/fish/config.fish` sources `_env.fish` and `_keybinds.fish`, then `load_files` over three dirs — `aliases/`, `attach/`, `utils/`. A new `.fish` file in one of those loads automatically; a **new directory** needs a `load_files` line added to `config.fish`.

- `aliases/*.fish` — `abbr` definitions grouped by tool (`_pacman`, `_docker`, `_network`, …).
- `utils/*.fish` — eagerly-sourced function definitions.
- `functions/*.fish` — fish's lazy autoload dir: one function per file, filename must match the function name.
- `conf.d/*.fish` — auto-sourced by fish itself before `config.fish`.
- `fish_variables` is machine-local and gitignored; anything that must travel with the repo is set with `set -g` in `_env.fish`.
- `plugins/` — fisher's install target (`fisher_path` is set in `conf.d/fisher_path.fish`). Files under `plugins/` are vendored by fisher from `fish_plugins`; regenerate via fisher rather than editing by hand. Fisher's own state (`_fisher_plugins`, `_fisher_*_files`) lives in the gitignored `fish_variables`, so `conf.d/fisher_sync.fish` re-seeds `_fisher_plugins` from `fish_plugins` on startup; run `fisher update` once after a clone to re-register file ownership. Without that seed, `fisher update` on a fresh clone treats every plugin as a conflicting install and then deletes `fish_plugins`.

## Vendored / generated files — do not hand-edit

- `dotfiles/apps/alacritty/themes/*.toml` — pulled by `themes.sh` from `alacritty/alacritty-theme`.
- `dotfiles/shell/tmux/tmux.conf` — oh-my-tmux upstream; all customization belongs in `tmux.conf.local`.
- `dotfiles/shell/fish/plugins/**` — fisher-managed.
- `dotfiles/editors/vim/.vim/autoload/plug.vim` — vim-plug.
- `dotfiles/editors/vscode/downloads/`, `extension_info/` — gitignored `.vsix` cache and Open VSX metadata written by `dotfiles/editors/vscode/extension-manager`, which is driven by `oss-extensions.txt` and prunes cache entries that aren't in it.

## Conventions

- Commits: Conventional Commits with a component scope — `feat(dnsproxy-changer): …`, `chore(fish): …`, `refactor(dns-scripts): …`, `fix(kde): …`.
- Bash scripts use tabs for indentation; fish uses 4 spaces.
- `.gitignore` excludes `**.auth` — VPN credential files are never committed; `dotfiles/home/.vpn/ovpn-servers/example.auth.txt` is the template.
- Keep `README.md`'s structure/flag/profile tables in sync when changing `stow.sh`, `bootstrap.sh` flags, Ansible profile steps, or `void-kde-setup` flags.
