# Modern dots configuration for any linux distro

## Overview

Modern dotfiles configuration for any Linux distribution. This repository contains configurations for various applications designed to enhance workflow and customize the Linux environment.

## Quick Installation

Clone the repository with shallow history to save bandwidth and disk space :

```bash
git clone --depth 1 https://github.com/void-land/void-dots.git ~/.dotfiles
cd ~/.dotfiles
```

The `--depth 1` flag fetches only the latest commit, significantly reducing clone time and repository size.

## Deploying Dotfiles

Execute the stow script to create symbolic links :

```bash
./stow.sh
```

This script automatically symlinks the configuration files from `~/.dotfiles` to their appropriate locations in the home directory. The actual files remain in the repository while appearing in the expected locations through symlinks.

## Removing Symlinks

To remove all symlinks created by stow :

```bash
stow -u
```

## Notes

Backup existing configuration files before running stow to avoid conflicts. If stow reports that target files already exist, remove or rename them before proceeding.
