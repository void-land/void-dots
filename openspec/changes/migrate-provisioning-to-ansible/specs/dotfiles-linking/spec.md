# Spec Delta

## Purpose

Ensures every provisioned machine ends with this repository checked out in the target user's home and its configs symlinked into place by `stow.sh`, with change reporting accurate enough to be driven by Ansible.

## ADDED Requirements

### Requirement: Repository present for the target user
The `dotfiles` step SHALL ensure the repository is cloned at the configured path in the target user's home (default `~/.void-dots`), from the configured URL and branch, owned by the target user. When the clone already exists it SHALL fast-forward it only if updates are enabled and the working tree is clean, and SHALL otherwise leave it untouched with a warning.

#### Scenario: Missing clone on a VPS
- **WHEN** the target user has no `~/.void-dots`
- **THEN** after the step the repo is cloned there and every file in it is owned by the target user

#### Scenario: Dirty clone
- **WHEN** the clone has uncommitted changes
- **THEN** the step does not modify the clone, prints a warning, and still links from the existing tree

### Requirement: Configs linked as the target user
The `dotfiles` step SHALL run `stow.sh -s` from the target user's clone as the target user (never as root), and SHALL run `stow.sh -n -s` instead under check mode.

#### Scenario: Links owned by user
- **WHEN** the step runs on a VPS where Ansible connects as root
- **THEN** the created symlinks live under the target user's home and are owned by the target user

#### Scenario: Check mode
- **WHEN** the step runs under `--check`
- **THEN** no symlink is created, moved or removed

### Requirement: stow.sh reports only real changes
`stow.sh -s` SHALL leave a target that is already a symlink to the correct source untouched and print nothing for it, and SHALL print one line per link it creates, replaces, backs up or prunes. Its linking rules, backup naming and `-u` / `-n` behaviour SHALL otherwise be unchanged.

#### Scenario: Second stow
- **WHEN** `stow.sh -s` is run twice in a row with no repo changes
- **THEN** the second run prints no create, backup or prune lines, and the `dotfiles` step reports no change

#### Scenario: Wrong symlink
- **WHEN** `~/.config/fish` is a symlink to a different directory
- **THEN** `stow.sh -s` replaces it with a link into the repo and prints a line for that link

#### Scenario: Real file in the way
- **WHEN** `~/.config/kitty` is a real directory
- **THEN** it is moved to `~/.config/kitty.bak.<timestamp>`, the link is created, and the step reports a change
