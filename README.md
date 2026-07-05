
# My Dotfiles

A modular, organized repository containing configuration files for my Linux environment. This setup utilizes a custom installation script to manage symlinks and configurations cleanly across the system, targeting a lightweight yet powerful terminal experience alongside the KDE Plasma desktop environment.

## 📂 Repository Structure

* **`_dotfiles/`**: Base application configurations (`~/.config/`). Includes extensive theme sets for **Alacritty** and **btop**, customized **Kitty** and **Rio** terminals, audio routing via **Pipewire**, and game performance tracking via **MangoHud**.

* **`_shell/`**: Shell configurations with a heavy focus on **Fish**. Features modularized aliases, custom completion scripts, `fzf` plugins via `fisher`, and multiplexer setups for both **Tmux** and **Zellij**.

* **`_plasma/`**: Configuration files for the **KDE Plasma** desktop suite, hardware profiles, and default application behaviors (`dolphinrc`, `kwinrc`, etc.).

* **`editors/`**: Text editor setups featuring **Zed** (complete with custom TSX/C snippets and themes) and standard **Vim**.

---

## 🛠️ Installation & Setup

This repository contains two automation scripts at the root level to bootstrap the environment:

### 1. System Provisioning (Arch/Endeavour)

The `arch-setup.sh` script installs necessary dependencies, system packages, and core utilities on a fresh Arch installation.

```bash
chmod +x arch-setup.sh
./arch-setup.sh
```

### 2. Symlink Configurations

The custom deployment script handles symlinking the repository components into their appropriate target locations in your `$HOME` directory.

```bash
chmod +x stow.sh
./stow.sh -s
```

---

## 🧰 Software Stack Summary

| Category | Utilities Configured |
| --- | --- |
| **Shell & Prompt** | Fish Shell, Starship Prompt, Bash |
| **Terminals** | Alacritty, Kitty, Rio |
| **Multiplexers** | Tmux |
| **Editors** | Zed |
| **System & Monitoring** | btop, htop, MangoHud |
| **Desktop Suite** | KDE Plasma (KWin, Dolphin, Baloo, PowerDevil) |
| **Audio** | Pipewire + Wireplumber (DeepFilter & Echo-Canceling) |
| **Media Player** | mpv (with AMD GPU hardware acceleration shaders) |
