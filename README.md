# 🐧 Void Dotfiles

<p align="center">
  <h4 align="center">A modular, organized dotfiles setup for a lightweight terminal experience alongside KDE Plasma</h4>
  <p align="center"><strong>Tested on:</strong> Arch Linux, EndeavourOS</p>
</p>

## Why this repo?

- Keep every config — shell, terminals, desktop, editors — **under version control**.
- **One-command bootstrap** on a fresh Arch install: run `arch-setup.sh`, then `stow.sh`.
- **Modular by design**: each app's config lives in its own folder, symlinked individually — remove what you don't need.
- **Interactive, not intrusive**: `arch-setup.sh` shows every step up front and lets you exclude what you don't want, instead of asking yes/no one function at a time.
- No stray copies scattered around `$HOME` — everything is a symlink back to this repo.

## 📂 Repository Structure

| Path | Description |
| --- | --- |
| `_dotfiles/` | Base application configs (`~/.config/`). Theme sets for **Alacritty** and **btop**, **Kitty** and **Rio** terminal setups, **Pipewire** audio routing, and **MangoHud** performance overlay. |
| `_shell/` | Shell configuration centered on **Fish** — modularized aliases, custom completions, `fzf` plugins via `fisher`, plus **Tmux** and **Zellij** multiplexer setups. |
| `_plasma/` | **KDE Plasma** configuration: hardware profiles and default app behavior (`dolphinrc`, `kwinrc`, etc.). |
| `editors/` | Editor setups for **Zed** (custom TSX/C snippets and themes) and standard **Vim**. |

## Quick start

1. **Clone** the repo:

   ```bash
   git clone https://github.com/void-land/void-dots.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Provision the system** (fresh Arch/EndeavourOS install only):

   ```bash
   chmod +x arch-setup.sh
   ./arch-setup.sh -s
   ```

3. **Symlink the configs:**

   ```bash
   chmod +x stow.sh
   ./stow.sh -s
   ```

4. **Log out and back in** (or reboot) so shell, group membership, and service changes take effect.

---

## 🛠️ System Provisioning (`arch-setup.sh`)

Bootstraps a fresh Arch install: system update, multilib, package groups, services, AUR packages, locale, Fish shell, KWin tweaks, and gaming environment setup (GameMode group + NTSync).

### Usage

```bash
./arch-setup.sh [-s | -a | -p | -m | -l | -f | -k | -g] [-h]
```

| Flag | Action |
| --- | --- |
| `-s` | Full system setup (all steps below) |
| `-a` | Install AUR packages only |
| `-p` | Install pacman packages only |
| `-m` | Enable multilib repository |
| `-l` | Setup locales (Persian) |
| `-f` | Setup Fish shell as default |
| `-k` | Apply KWin / graphics performance tweaks |
| `-g` | Configure gaming environment (GameMode group, NTSync) |
| `-h` | Show help |

### How step selection works

Running `-s` doesn't ask yes/no before every step. Instead it prints every step once, `yay`-style, and lets you exclude what you don't want:

```
:: Following steps will be executed:
 1  Update system
 2  Enable multilib repository
 3  Install pacman packages
 4  Enable system services
 5  Enable user services
 6  Install AUR packages
 7  Setup Persian locale (fa_IR UTF-8)
 8  Setup Fish shell as default
 9  Configure gaming environment (GameMode group, NTSync)
==> Steps to exclude: (eg: "1 2 3", "1-3", "^4")
 -> Excluding steps may result in a partial setup
==>
```

Type numbers, a range (`7-9`), or `^4`, and press Enter — everything else runs without further prompts. The same exclude-style picker is used inside `-p` (package groups) and `-a` (individual AUR packages), so you can drop e.g. `google-chrome` or the whole `GAMING_PACKAGES` group on the fly.

### Gaming environment (`-g`)

- Adds your user to the `gamemode` group (skips if already a member; warns if `gamemode` isn't installed yet).
- Detects NTSync support (kernel ≥ 6.14 **and** built with `CONFIG_NTSYNC`) before touching anything — if unsupported, it says so and skips cleanly.
- When supported: writes `/etc/modules-load.d/ntsync.conf` so `ntsync` persists across reboots, then loads it for the current session.
- Verify anytime with:

  ```bash
  gamemoded -t
  lsmod | grep -i ntsync
  ```

---

## 🔗 Managing Configuration (`stow.sh`)

Symlinks the contents of `_dotfiles/`, `_shell/`, `_plasma/`, and `editors/` into their target locations under `$HOME` and `~/.config/`.

**Link (stow) configurations:**

```bash
./stow.sh -s
```

*Creates the necessary directories under `~/.config/` and symlinks every tracked file back into this repo.*

**Unlink (unstow) configurations:**

```bash
./stow.sh -u
```

*Removes the symlinks, detaching your system from the repo without deleting the source files.*

---

## 🧰 Software Stack Summary

| Category | Utilities Configured |
| --- | --- |
| **Shell & Prompt** | Fish Shell, Starship Prompt, Bash |
| **Terminals** | Alacritty, Kitty, Rio |
| **Multiplexers** | Tmux, Zellij |
| **Editors** | VsCode, Zed, Vim |
| **System & Monitoring** | btop, htop, MangoHud |
| **Desktop Suite** | KDE Plasma (KWin, Dolphin, Baloo, PowerDevil) |
| **Audio** | Pipewire + Wireplumber (DeepFilter & Echo-Canceling) |
| **Media Player** | vlc |
| **Gaming** | Steam, MangoHud, GameMode, NTSync |
