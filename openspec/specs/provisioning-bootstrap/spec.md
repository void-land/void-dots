# provisioning-bootstrap Specification

## Purpose

Provides a single pasteable command that prepares any supported machine (installs Ansible, fetches the repo) and applies the right provisioning profile to it, interactively by default and unattended on request.

## Requirements

### Requirement: One-line entry point
The repository SHALL provide `bootstrap.sh` at its root, runnable both from a clone and as `bash -c "$(curl -fsSL https://raw.githubusercontent.com/void-land/void-dots/main/bootstrap.sh)"`, with a `-h` usage listing every flag.

#### Scenario: Run from curl on a fresh machine
- **WHEN** the one-liner is pasted into a shell on a supported machine with no clone of the repo
- **THEN** the script completes the full bootstrap without requiring any file other than itself to be present beforehand

#### Scenario: Help
- **WHEN** `bootstrap.sh -h` is run
- **THEN** it prints usage with every flag and exits 0 without changing the system

### Requirement: Distro detection selects the profile
The bootstrap SHALL read `/etc/os-release` and map Arch and Arch derivatives (including EndeavourOS) to `arch_desktop`, Debian to `debian_vps`, and Ubuntu to `ubuntu_vps`. A `-p <profile>` flag SHALL override detection. Unsupported distributions SHALL abort with a message listing the supported ones.

#### Scenario: EndeavourOS
- **WHEN** the bootstrap runs on EndeavourOS
- **THEN** it selects the `arch_desktop` profile

#### Scenario: Unsupported distro
- **WHEN** the bootstrap runs on Fedora without `-p`
- **THEN** it exits non-zero naming the detected distribution and the supported ones, before installing anything

#### Scenario: Explicit profile mismatching the distro
- **WHEN** `-p arch_desktop` is given on an Ubuntu machine
- **THEN** the run stops at profile preflight without changing the system

### Requirement: Privilege model per profile
The bootstrap SHALL refuse to run `arch_desktop` as root and SHALL run it as the invoking user, asking for the sudo password once. For VPS profiles it SHALL accept running as root, or as a sudo-capable user, in which case it escalates with sudo.

#### Scenario: Arch as root
- **WHEN** the bootstrap is run as root on Arch
- **THEN** it exits non-zero telling the user to run it as their regular user

#### Scenario: VPS as root
- **WHEN** the bootstrap is run as root on a Debian VPS
- **THEN** it proceeds without asking for a sudo password

### Requirement: Ansible installation
The bootstrap SHALL ensure `git`, `python3` and `ansible-core` at or above the project's minimum version are available. It SHALL install `ansible-core` from the distribution when that version is sufficient, and otherwise into a dedicated Python virtual environment that it reuses on later runs. It SHALL NOT install Galaxy content.

#### Scenario: Distro ansible-core too old
- **WHEN** the distribution's `ansible-core` package is older than the minimum
- **THEN** the bootstrap installs a supported `ansible-core` into its virtual environment and uses that for the run

#### Scenario: Ansible already present
- **WHEN** a sufficient `ansible-playbook` is already installed
- **THEN** the bootstrap does not reinstall it

### Requirement: Repository clone and update
The bootstrap SHALL clone the repository into `~/.void-dots` (overridable by flag) when it is absent, and fast-forward it when present and clean. If the clone has local changes or cannot fast-forward, it SHALL warn and continue with the checked-out state instead of aborting.

#### Scenario: Existing clone with local edits
- **WHEN** `~/.void-dots` exists with uncommitted changes
- **THEN** the bootstrap prints a warning that it did not update the clone and runs the playbook from the current working tree

### Requirement: Interactive step selection
By default the bootstrap SHALL show the selected profile's steps in the existing yay-style exclude picker (accepting `1 2 3`, `1-3`, `^4`) and SHALL translate exclusions into skipped steps. When the package step remains selected, it SHALL offer the same picker for that profile's package groups.

#### Scenario: Excluding steps
- **WHEN** the user excludes the AUR and gaming steps in the picker
- **THEN** the playbook runs every other step and skips those two

#### Scenario: Excluding a package group
- **WHEN** the user excludes the gaming package group in the group picker
- **THEN** the packages step installs every other group and none of the gaming group's packages

### Requirement: Collect inputs before the run
In interactive mode the bootstrap SHALL ask for every input the selected steps need (VPS target user, swap size, timezone, and a new user's password) before starting the playbook, so the run itself needs no further input. A new user's password SHALL be read without echo, passed to the playbook only as a hash, and never appear on a command line; any temporary file holding the hash SHALL be readable only by the invoking user and removed when the bootstrap exits, including on interrupt.

#### Scenario: VPS with new user
- **WHEN** the user selects the sudo-user step for a user that does not exist yet
- **THEN** the bootstrap prompts for the password twice without echo before the playbook starts, and the playbook creates the user with that password

### Requirement: Non-interactive mode
The bootstrap SHALL accept `-y` to skip all pickers and prompts and apply defaults, `-t` / `-x` to select or skip steps by id, `-n` for a dry run, and `-e` (repeatable) for extra variables, and SHALL pass any arguments after `--` to `ansible-playbook` unchanged. In `-y` mode a missing required input SHALL fail the run rather than prompt.

#### Scenario: Unattended dry run
- **WHEN** `bootstrap.sh -y -n` is run
- **THEN** no picker or prompt is shown and the profile runs in check mode

#### Scenario: Unattended VPS without user
- **WHEN** `bootstrap.sh -y` is run on a VPS with no target user given
- **THEN** the run fails at preflight naming the missing target user

### Requirement: Readable outcome
The bootstrap SHALL print the selected profile and steps before running, and on completion SHALL print whether the run succeeded and that a re-login or reboot is needed for shell, group and service changes. On failure it SHALL exit non-zero with the playbook's exit code.

#### Scenario: Playbook failure
- **WHEN** a task fails during the playbook
- **THEN** the bootstrap exits with the playbook's non-zero exit code and does not print the success message
