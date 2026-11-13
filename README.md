# 🐧 Void Dotfiles

<p align="center">
  <h4 align="center">A modular, organized dotfiles setup for a lightweight terminal experience alongside KDE Plasma</h4>
  <p align="center"><strong>Tested on:</strong> Arch Linux, EndeavourOS</p>
</p>

## Why this repo?

- Keep every config — shell, terminals, desktop, editors — **under version control**.
- **One-command bootstrap** on a fresh Arch desktop or Debian/Ubuntu VPS: one pasted line detects the distro, installs `ansible-core`, and applies the matching Ansible profile, including linking the dotfiles.
- **Modular by design**: each app's config lives in its own folder, symlinked individually — remove what you don't need.
- **Interactive, not intrusive**: `bootstrap.sh` and `void-kde-setup` show every step up front and let you exclude what you don't want, instead of asking yes/no one function at a time.
- **Plain Ansible, nothing third-party**: provisioning is declarative and idempotent, with dry runs (`-n`), and can be pushed to a VPS over SSH. It uses only `ansible-core` builtins plus two modules written in this repo.
- No stray copies scattered around `$HOME` — everything is a symlink back to this repo, except KDE settings, which are applied from one config file (see below).

## 📂 Repository Structure

| Path | Description |
| --- | --- |
The repo root holds only the tooling (`bootstrap.sh`, `stow.sh`, `lint.sh`, `ansible/`) and docs; everything that gets deployed lives under `dotfiles/`:

| Path | Description |
| --- | --- |
| `ansible/` | **Provisioning**: profiles for an Arch desktop and Debian/Ubuntu VPSes (see Ansible Provisioning below). Driven by `bootstrap.sh`. |
| `dotfiles/apps/` | Application configs (`~/.config/`). Theme sets for **Alacritty** and **btop**, **Kitty** and **Rio** terminal setups, **Pipewire** audio routing, and **MangoHud** performance overlay. |
| `dotfiles/shell/` | Shell configuration centered on **Fish** — modularized aliases, custom completions, `fzf` plugins via `fisher`, plus a **Tmux** multiplexer setup (`~/.config/`). |
| `dotfiles/editors/` | Editor setups for **VS Code / VSCodium** (settings, TS snippets, and an Open VSX extension manager — see [`dotfiles/editors/vscode`](dotfiles/editors/vscode/README.md)), **Zed** (custom TSX/C snippets and themes), and standard **Vim**. |
| `dotfiles/kde/` | **KDE Plasma** settings in one file, `settings.conf`: shortcuts, effects (magic lamp, blur), virtual desktops, keyboard layouts, power, default apps, panel, and session env vars. Applied by `void-kde-setup`, not symlinked. |
| `dotfiles/home/` | Directories linked straight into `~` — `~/.vpn` (OpenVPN/OpenConnect wrappers) and `~/.ucu` (umu/Proton game launchers). |
| `dotfiles/scripts/` | `void-*` utility scripts (DNS, zram, Steam, KDE setup, …), linked to `~/.scripts` and on `PATH`. |

## Quick start

1. **Bootstrap** on a fresh Arch/EndeavourOS desktop (as your user) or a Debian 12+/Ubuntu 22.04+ VPS (as root or a sudo user):

   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/void-land/void-dots/main/bootstrap.sh)"
   ```

   This runs whatever is on `main`. If you'd rather read it first, clone and run it from the clone. It then uses that clone instead of `~/.void-dots`:

   ```bash
   git clone https://github.com/void-land/void-dots.git ~/.void-dots
   ~/.void-dots/bootstrap.sh
   ```

   It detects the distro and picks the profile (`arch_desktop`, `debian_vps` or `ubuntu_vps`). It installs `git` and `ansible-core`: from the distro, or a pinned version in a venv when the distro's is older than 2.14 (Ubuntu 22.04). It then clones or fast-forwards the repo, shows the steps (and package groups) so you can exclude some, and asks for any input up front: the VPS user and its password, swap size, timezone. Then it runs the playbook. Dotfiles are linked by the `dotfiles` step, which runs `stow.sh` for you.

2. **Log out and back in** (or reboot) so shell, group membership, and service changes take effect.

To work on the repo itself, install the tools `lint.sh` uses: `shellcheck`, `shfmt`, `fish`, and optionally `ansible-lint`. The fish config expects Starship. On Debian/Ubuntu releases that don't package it, install it with `curl -sS https://starship.rs/install.sh | sh`.

### `bootstrap.sh` options

```bash
./bootstrap.sh [-p <profile>] [-y] [-n] [-t <steps>] [-x <steps>] [-u <user>] [-e <var=value>]... [-d <dir>] [-b <branch>] [-h] [-- <ansible-playbook args>]
```

| Flag | Action |
| --- | --- |
| `-p <profile>` | Force `arch_desktop`, `debian_vps` or `ubuntu_vps` instead of detecting |
| `-y` | Unattended: no pickers or prompts. A missing required input (e.g. the VPS user) fails the run |
| `-n` | Dry run (`ansible-playbook --check`): report what would change, change nothing |
| `-t <steps>` / `-x <steps>` | Only run / skip these comma-separated step ids (no picker) |
| `-u <user>` | Target non-root user (VPS: the sudo user to create/configure) |
| `-e <var=value>` | Extra Ansible variable, repeatable (e.g. `-e swap_size=4G`) |
| `-d <dir>` / `-b <branch>` | Clone location (default `~/.void-dots`) / branch (default `main`) |
| `-- <args>` | Passed to `ansible-playbook` unchanged (e.g. `-- -v --diff`) |

```bash
./bootstrap.sh -n                      # dry run with pickers
./bootstrap.sh -y -x aur,gaming        # everything except AUR and gaming, no questions
./bootstrap.sh -t dotfiles             # only re-link the dotfiles
./bootstrap.sh -y -u deploy -e timezone_name=UTC   # VPS, unattended (user must already exist)
```

`void-arch-setup` and `void-debian-vps-setup` were removed in favour of the Ansible profiles. Their flags map to step ids like this:

| Old command | Now |
| --- | --- |
| `void-arch-setup -s` | `./bootstrap.sh` |
| `void-arch-setup -p` / `-a` / `-m` | `./bootstrap.sh -t packages` / `-t aur` / `-t pacman_config` |
| `void-arch-setup -l` / `-f` / `-g` / `-e` | `./bootstrap.sh -t locale` / `-t shell` / `-t gaming` / `-t display_manager` |
| `void-debian-vps-setup -s` | `./bootstrap.sh` (on the VPS) |
| `void-debian-vps-setup -p` / `-a` / `-d` | `./bootstrap.sh -t packages` / `-t user` / `-t docker` |
| `void-debian-vps-setup -w` / `-t` / `-f` | `./bootstrap.sh -t swap` / `-t timezone` / `-t shell` |
| `void-debian-vps-setup -u <user>` | `./bootstrap.sh -u <user>` |

---

## ⚙️ Ansible Provisioning (`ansible/`)

Provisioning is a self-contained Ansible project that only needs **`ansible-core`**. No Galaxy roles or collections are used: tasks use `ansible.builtin.*`, plus two modules written in this repo (`ansible/library/void_pacman.py` for pacman, `void_aur.py` for AUR builds via `makepkg`). `ansible.cfg` stops Ansible from finding installed collections, and `./lint.sh` rejects any other module.

| Profile | Inventory group | Playbook | Steps (tags) |
| --- | --- | --- | --- |
| Arch / EndeavourOS desktop | `arch_desktop` | `playbooks/arch_desktop.yml` | `pacman_config`, `system_update`, `packages`, `services`, `display_manager`, `aur`, `locale`, `shell`, `gaming`, `dotfiles` |
| Debian 12+ VPS | `debian_vps` (in `vps`) | `playbooks/vps.yml` | `system_update`, `packages`, `user`, `docker`, `swap`, `timezone`, `shell`, `dotfiles` |
| Ubuntu 22.04+ VPS | `ubuntu_vps` (in `vps`) | `playbooks/vps.yml` | same as Debian |

```
ansible/
├── ansible.cfg              # builtin-only config (run with ANSIBLE_CONFIG pointing here)
├── site.yml                 # every profile, for mixed inventories
├── playbooks/               # one playbook per profile; each role is a tagged step
├── inventory/
│   ├── local.yml            # local-arch / local-debian / local-ubuntu → this machine
│   ├── hosts.example.yml    # template for remote hosts (copy to hosts.yml, git-ignored)
│   ├── group_vars/          # all < vps < debian_vps / ubuntu_vps; arch_desktop
│   └── host_vars/           # per-host overrides and secrets (git-ignored)
├── roles/                   # one role per step, plus preflight
├── library/                 # void_pacman, void_aur
└── module_utils/            # shared helpers for the modules
```

Everything a profile does is data in `inventory/group_vars/`: package groups (ordered `{name, packages}` lists), AUR packages, services, the display manager, locales, swap size, timezone. Change it there, or per host in `host_vars/`, or once with `-e`. Each profile also lists its steps in `void_profile_steps`; that list must match the tagged roles in its playbook (`./lint.sh` checks).

### Run locally

`bootstrap.sh` (see Quick start) handles this for you. By hand, from `ansible/`:

```bash
export ANSIBLE_CONFIG=$PWD/ansible.cfg
ansible-playbook -i inventory/local.yml -l local-arch playbooks/arch_desktop.yml -K --check   # dry run
ansible-playbook -i inventory/local.yml -l local-arch playbooks/arch_desktop.yml -K -t aur,gaming
ansible-playbook -i inventory/local.yml -l local-arch playbooks/arch_desktop.yml -K -e '{"packages_exclude_groups":["gaming"]}'
```

### Push to a VPS over SSH

```bash
cd ansible && export ANSIBLE_CONFIG=$PWD/ansible.cfg
cp inventory/hosts.example.yml inventory/hosts.yml       # edit hosts, ansible_user, void_target_user
$EDITOR inventory/host_vars/my-debian-vps.yml            # user_password_hash, user_ssh_keys, timezone_name, ...
ansible-vault encrypt inventory/host_vars/my-debian-vps.yml
ansible-playbook -i inventory/hosts.yml playbooks/vps.yml --list-tasks                     # what would run
ansible-playbook -i inventory/hosts.yml playbooks/vps.yml -l my-debian-vps --ask-vault-pass --check
ansible-playbook -i inventory/hosts.yml playbooks/vps.yml -l my-debian-vps --ask-vault-pass
```

Generate the password hash with `openssl passwd -6`. If `ansible_user` isn't root, it needs sudo: put `ansible_become_password` in the vaulted host_vars, or pass `-K`. A new user's password is only set when the user is created. To change an existing user's password, set `user_update_password: true`.


### Step notes

- **`display_manager`** disables SDDM, GDM, LightDM, ly, LXDM and greetd but doesn't stop them, so your current session survives. emptty takes over at the next boot.
- **`aur`** builds each package with `makepkg` as your user, in `~/.cache/void-dots/aur/<pkg>`, then installs it with `pacman -U`. No AUR helper is needed; `yay` is installed as one of the packages for interactive use. Packages whose dependencies are only on the AUR aren't supported.
- **`gaming`** adds you to the `gamemode` group. If the kernel is 6.14+ **and** built with `CONFIG_NTSYNC`, it writes `/etc/modules-load.d/ntsync.conf` and loads `ntsync`; otherwise it says so and skips. To verify: `gamemoded -t` and `lsmod | grep -i ntsync`.
- **`docker`** installs `docker.io`, plus compose (`docker-compose-v2` on Ubuntu, `docker-compose` on Debian, which is the old v1 `docker-compose` command on bookworm) and `docker-buildx` when available. It writes log rotation to `/etc/docker/daemon.json` only if that file doesn't exist, and adds the user to `docker`.
- **`swap`** is skipped when any swap is already active. Otherwise it creates `/swapfile` (`swap_size`, default 2G) and sets `vm.swappiness=10`.
- **`user`** copies root's `authorized_keys` to the new user when `user_ssh_keys` is empty and the user has none.
---

## 🔗 Managing Configuration (`stow.sh`)

Symlinks the contents of `dotfiles/home/`, `dotfiles/apps/`, `dotfiles/shell/`, and `dotfiles/editors/` into their target locations under `$HOME` and `~/.config/`, and links `dotfiles/scripts/` to `~/.scripts`. VS Code configs from `dotfiles/editors/vscode/configs/` are linked into both `~/.config/VSCodium/User/` and `~/.config/Code - OSS/User/`.

**Link (stow) configurations:**

```bash
./stow.sh -s
```

*Creates the necessary directories under `~/.config/` and symlinks every tracked file back into this repo. Works from any directory. An existing real file or directory at a target is moved aside to `<name>.bak.<timestamp>` rather than overwritten. Symlinks that point into the repo at files that no longer exist are pruned first. Links that already point at the right place are skipped silently, so a re-run only prints what it actually changed.*

*KDE settings are not touched; run `void-kde-setup` yourself to apply them (see below).*

**Unlink (unstow) configurations:**

```bash
./stow.sh -u
```

*Removes only the symlinks that point back into this repo, detaching your system without deleting the source files. Anything else at a target path is left untouched.*

**Preview without changing anything:** add `-n` (dry run) to either command, e.g. `./stow.sh -n -s`.

---

## 🎨 KDE Settings (`void-kde-setup`)

KDE rewrites its rc files during normal use, so they aren't symlinked. Every setting worth keeping lives in [`dotfiles/kde/settings.conf`](dotfiles/kde/settings.conf) as plain bash variables, and `void-kde-setup` writes them with `kwriteconfig6`, reloading KWin over D-Bus where it can. The file covers:

- **Shortcuts** (`KDE_SHORTCUTS`): only the ones that differ from Plasma's defaults, e.g. `Meta+Q` → Alacritty, `Meta+C` close window, `Meta+Space` next keyboard layout.
- **Effects** (`KWIN_EFFECTS_ENABLE` / `_DISABLE`): magic lamp and blur on, squash off.
- **Virtual desktops** (`KDE_DESKTOPS`): Browsers, Code, Social, Gaming.
- **Session env** (`KDE_SESSION_ENV`): written to `~/.config/plasma-workspace/env/void-env.sh`, e.g. `KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1`.
- **Everything else** (`KDE_CONFIG`): `file|group|key|value` rows for keyboard layouts, mouse, power, Baloo, Dolphin, the file dialog, and so on, plus default apps (`KDE_MIME_DEFAULTS`), theme, and panel (height, pager, pinned launchers via `void-kde-panel`).

```bash
void-kde-setup                      # pick steps to exclude, apply the rest
void-kde-setup -y                   # apply everything, no picker
void-kde-setup -o shortcuts,effects # only some steps (-l lists them)
void-kde-setup -n                   # dry run
void-kde-setup -c                   # drift check: what changed in System Settings?
```

| Flag | Action |
| --- | --- |
| `-o <steps>` | Run only these steps, comma-separated |
| `-y` | Apply every step without the picker |
| `-n` | Dry run: print what would be written |
| `-R` | Don't restart plasmashell after the panel step |
| `-c` | Compare the live desktop to `settings.conf` and list differences |
| `-l` | List steps |
| `-h` | Show help |

Shortcuts and session env vars take effect at the next login. KWin hosts kglobalaccel and has no reload call for it. Everything else applies live. Per-install state, like tiling layouts (keyed by desktop × monitor UUID), is deliberately not tracked.

After changing something in System Settings that you want to keep, run `void-kde-setup -c` and copy the reported value into `settings.conf`.

---

## 🧰 Software Stack Summary

| Category | Utilities Configured |
| --- | --- |
| **Shell & Prompt** | Fish Shell, Starship Prompt, Bash |
| **Terminals** | Alacritty, Kitty, Rio |
| **Multiplexers** | Tmux |
| **Editors** | VsCode, Zed, Vim |
| **System & Monitoring** | btop, htop, MangoHud |
| **Desktop Suite** | KDE Plasma (KWin, Dolphin, Baloo, PowerDevil) |
| **Audio** | Pipewire + Wireplumber (DeepFilter & Echo-Canceling) |
| **Media Player** | vlc |
| **Gaming** | Steam, MangoHud, GameMode, NTSync |
