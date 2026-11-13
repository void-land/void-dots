# arch-desktop-profile Specification

## Purpose

Defines what applying the `arch_desktop` profile achieves on an Arch Linux or EndeavourOS workstation, replacing the behaviour of the removed `void-arch-setup` script.

## Requirements

### Requirement: Arch desktop steps
The `arch_desktop` profile SHALL provide these steps, in this order, each addressable by its id: `pacman_config`, `system_update`, `packages`, `services`, `display_manager`, `aur`, `locale`, `shell`, `gaming`, `dotfiles`.

#### Scenario: Listing steps
- **WHEN** the profile's tasks are listed (e.g. `ansible-playbook --list-tags`)
- **THEN** every step id above is present as a tag

### Requirement: Pacman configuration and multilib
The `pacman_config` step SHALL set `ParallelDownloads` to the configured value (default 12), enable `Color`, enable the `[multilib]` repository, and refresh the package databases only when one of these settings changed.

#### Scenario: Multilib disabled
- **WHEN** `/etc/pacman.conf` has `[multilib]` and its `Include` line commented out
- **THEN** after the step both lines are uncommented and the databases were refreshed once

#### Scenario: Already configured
- **WHEN** all three settings are already in place
- **THEN** the step reports no change and does not refresh databases

### Requirement: Full system upgrade
The `system_update` step SHALL perform a full sync-and-upgrade of repository packages and report `changed` only when packages were upgraded.

#### Scenario: Up-to-date system
- **WHEN** no package updates are available
- **THEN** the step reports no change

### Requirement: Repository package groups
The `packages` step SHALL install, without reinstalling present packages, every package of the profile's ordered package groups (`base`, `audio`, `gpu`, `gaming`, `utilities`, `fonts`, initially with the same contents as the removed script), except groups listed in the exclusion variable.

#### Scenario: Gaming group excluded
- **WHEN** the gaming group is in the exclusion list
- **THEN** none of that group's packages are installed by the step, and every other group's packages are

### Requirement: AUR packages without an AUR helper
The `aur` step SHALL build and install each configured AUR package (initially `vscodium-bin`, `google-chrome`, `vazirmatn-fonts`, plus `yay` for interactive use) as the target user without requiring an AUR helper to be pre-installed, SHALL skip packages already installed, and SHALL support per-package exclusion.

#### Scenario: Fresh machine
- **WHEN** none of the AUR packages are installed and no AUR helper exists
- **THEN** after the step all non-excluded AUR packages are installed, and the build ran as the target user, not root

#### Scenario: Package already installed
- **WHEN** `google-chrome` is already installed
- **THEN** the step does not rebuild it

### Requirement: System and user services
The `services` step SHALL enable and start the configured system services (initially `NetworkManager`, `bluetooth`) and SHALL enable the configured user services (initially `pipewire`, `wireplumber`, `pipewire-pulse`) for user sessions without requiring an active user session during the run.

#### Scenario: Run over a non-graphical session
- **WHEN** the step runs from a TTY or SSH session with no user D-Bus session
- **THEN** the user services are enabled and become active at the next login

### Requirement: emptty display manager
The `display_manager` step SHALL disable and stop any enabled or active display manager from the configured conflict list (initially `sddm`, `gdm`, `lightdm`, `ly`, `lxdm`, `greetd`) and enable `emptty`. It SHALL NOT stop the display manager of the session the run is executing in before the run completes.

#### Scenario: SDDM enabled
- **WHEN** `sddm.service` is enabled
- **THEN** after the step `sddm.service` is disabled and `emptty.service` is enabled, taking over at next boot

### Requirement: Locales
The `locale` step SHALL enable each configured locale (initially `fa_IR UTF-8`) in `/etc/locale.gen` and regenerate locales only when the file changed.

#### Scenario: Persian locale already enabled
- **WHEN** `fa_IR UTF-8` is already uncommented
- **THEN** the step reports no change and does not run locale generation

### Requirement: Fish login shell
The `shell` step SHALL ensure fish is listed in `/etc/shells` and is the target user's login shell.

#### Scenario: Bash user
- **WHEN** the target user's login shell is bash
- **THEN** after the step their login shell is fish's path

### Requirement: Gaming environment
The `gaming` step SHALL add the target user to the `gamemode` group, failing with a clear message if the group does not exist. It SHALL persist the `ntsync` module across reboots and load it now only when the running kernel is 6.14 or newer and built with NTSync; otherwise it SHALL skip NTSync with a message and not fail.

#### Scenario: Old kernel
- **WHEN** the running kernel is 6.12
- **THEN** the step reports that NTSync is unavailable, writes no module-load configuration, and succeeds

#### Scenario: Supported kernel
- **WHEN** the kernel is 6.18 built with `CONFIG_NTSYNC=m`
- **THEN** `ntsync` is configured to load at boot and is loaded after the step

### Requirement: Target user is the invoking user
The profile SHALL apply user-scoped steps (AUR builds, user services, shell, groups, dotfiles) to the non-root user who started the run unless a target user is explicitly configured, and SHALL refuse to use `root` as the target user.

#### Scenario: Default target user
- **WHEN** user `alice` runs the profile without configuring a target user
- **THEN** fish becomes `alice`'s shell and `alice` is added to the `gamemode` group
