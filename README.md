# Modern dots configuration for any linux distro

## Overview

Modern dotfiles configuration for any Linux distribution. This repository contains configurations for various applications designed to enhance workflow and customize the Linux environment.

## Quick Installation

Clone the repository with shallow history to save bandwidth and disk space :

```bash
git clone https://github.com/void-land/void-dots.git ~/.void-dots --depth 1
cd ~/.void-dots
```

The `--depth 1` flag fetches only the latest commit, significantly reducing clone time and repository size.

## Deploying Dotfiles

Execute the stow script to create symbolic links :

```bash
./stow.sh
```

This script automatically symlinks the configuration files from `~/.void-dots` to their appropriate locations in the home directory. The actual files remain in the repository while appearing in the expected locations through symlinks.

## Removing Symlinks

To remove all symlinks created by stow :

```bash
stow -u
```

## Updating / Pulling Changes

To pull the latest updates:

```bash
git pull
```

If you receive an error about local changes being overwritten (e.g., `shells/fish/fish_variables`), you can stash your changes, pull, and then apply them back:

```bash
git stash
git pull
git stash pop
```

Alternatively, to discard local changes and reset a specific file:

```bash
git checkout -- shells/fish/fish_variables
git pull
```

## Notes

Backup existing configuration files before running stow to avoid conflicts. If stow reports that target files already exist, remove or rename them before proceeding.
