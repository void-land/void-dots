# Spec Delta

## Purpose

Defines what applying the `debian_vps` or `ubuntu_vps` profile achieves on a Debian or Ubuntu server, either on the server itself or pushed over SSH, replacing the behaviour of the removed `void-debian-vps-setup` script.

## ADDED Requirements

### Requirement: VPS steps
The `debian_vps` and `ubuntu_vps` profiles SHALL provide these steps, in this order, each addressable by its id: `system_update`, `packages`, `user`, `docker`, `swap`, `timezone`, `shell`, `dotfiles`. Both profiles SHALL share the same step implementations and differ only in profile variables.

#### Scenario: Same steps on both distros
- **WHEN** the tags of the `debian_vps` and `ubuntu_vps` profiles are listed
- **THEN** both list the same step ids

### Requirement: Supported releases
The VPS profiles SHALL support Debian 12 and 13 and Ubuntu 22.04 and 24.04 (and later LTS releases unless preflight is updated otherwise), and preflight SHALL reject other releases of those distributions with a clear message.

#### Scenario: Debian 11
- **WHEN** the `debian_vps` profile runs on Debian 11
- **THEN** preflight fails naming the unsupported release

### Requirement: Non-interactive package management
The `system_update` and `packages` steps SHALL refresh the apt cache, perform a full upgrade, and install the profile's ordered package groups (`base`, `utilities`, `network`, initially with the removed script's contents) without interactive prompts and keeping existing modified configuration files. Group exclusion SHALL work as in the Arch profile.

#### Scenario: Modified config file during upgrade
- **WHEN** an upgraded package ships a new version of a config file the admin edited
- **THEN** the upgrade keeps the admin's version and does not wait for input

### Requirement: Sudo user
The `user` step SHALL ensure the target user exists with a home directory and is in the `sudo` group. When creating the user it SHALL set the supplied password hash, and SHALL fail before creating the user if no hash is supplied. It SHALL NOT change an existing user's password unless explicitly asked.

#### Scenario: Existing user
- **WHEN** the target user already exists and is not in `sudo`
- **THEN** the user is added to `sudo` and their password is unchanged

#### Scenario: New user without password
- **WHEN** the target user does not exist and no password hash is supplied
- **THEN** the step fails with a message explaining how to supply one, and no user is created

### Requirement: SSH keys for the sudo user
The `user` step SHALL install every public key listed in the profile's SSH key variable into the target user's `authorized_keys`. When that list is empty and the user has no `authorized_keys`, it SHALL copy root's `authorized_keys` if present. It SHALL never remove existing keys, and SHALL enforce `700` on `~/.ssh` and `600` on `authorized_keys`, owned by the user.

#### Scenario: Fresh VPS with root key only
- **WHEN** root has an `authorized_keys` file, the target user has none, and no keys are configured
- **THEN** the target user's `authorized_keys` equals root's

#### Scenario: Configured keys
- **WHEN** two public keys are configured and the user already has a different key
- **THEN** the user's `authorized_keys` contains all three keys

### Requirement: Docker from distribution repositories
The `docker` step SHALL install `docker.io` plus the distribution's Compose package (`docker-compose-v2` where available, otherwise `docker-compose`, otherwise none with a warning) and `docker-buildx` when available. It SHALL write container log rotation (`json-file`, `10m` x `3`) to `/etc/docker/daemon.json` only if that file does not exist, enable Docker and containerd, and add the target user to the `docker` group.

#### Scenario: Ubuntu 24.04
- **WHEN** the step runs on Ubuntu 24.04
- **THEN** `docker.io`, `docker-compose-v2` and `docker-buildx` are installed and `docker compose version` succeeds

#### Scenario: Existing daemon.json
- **WHEN** `/etc/docker/daemon.json` already exists with custom content
- **THEN** its content is unchanged after the step

#### Scenario: daemon.json changes restart Docker
- **WHEN** the step writes `daemon.json` for the first time
- **THEN** the Docker service is restarted once so the setting applies

### Requirement: Swapfile
The `swap` step SHALL do nothing if any swap is already active. Otherwise it SHALL create a swapfile of the configured size (default `2G`) at the configured path (default `/swapfile`) with mode `600`, activate it, persist it in `/etc/fstab`, and set `vm.swappiness` to the configured value (default `10`) persistently. If activation fails (e.g. in containers that cannot swap), it SHALL remove the swapfile and fail with a message.

#### Scenario: No swap
- **WHEN** no swap is active on a 1 GB VPS
- **THEN** after the step a 2 GB swapfile is active, listed in `/etc/fstab`, and `vm.swappiness` is 10

#### Scenario: Swap already active
- **WHEN** a swap partition is already active
- **THEN** the step creates no swapfile and reports no change

### Requirement: Timezone and NTP
The `timezone` step SHALL set the configured timezone (default: keep the current one) only when it differs, SHALL reject a timezone not present in the zoneinfo database, and SHALL enable NTP synchronisation where systemd's time services are available. Where they are not, it SHALL set the timezone through `/etc/localtime` and `/etc/timezone` and warn that NTP was not configured.

#### Scenario: Invalid timezone
- **WHEN** the configured timezone is `Mars/Base`
- **THEN** preflight fails naming the invalid timezone

### Requirement: Fish shell for the target user
The `shell` step SHALL make fish the target user's login shell and ensure it is listed in `/etc/shells`, failing with a message if the target user does not exist.

#### Scenario: Shell step without user step
- **WHEN** only the `shell` step runs and the target user does not exist
- **THEN** the step fails naming the missing user

### Requirement: Explicit, validated target user
The VPS profiles SHALL require an explicitly configured target user, which SHALL be a valid lowercase POSIX username other than `root`.

#### Scenario: Root as target
- **WHEN** the target user is configured as `root`
- **THEN** preflight fails before any change

### Requirement: Local and remote execution
Each VPS profile SHALL produce the same result whether applied on the server through the local inventory or pushed from another machine over SSH through the remote inventory, connecting either as root or as a sudo-capable user with privilege escalation.

#### Scenario: Push from laptop
- **WHEN** the user runs the VPS playbook from their laptop against a host in the remote inventory, connecting as root over SSH
- **THEN** the VPS ends in the same state as if the bootstrap had been run on it with the same variables
