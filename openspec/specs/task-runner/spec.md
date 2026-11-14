# task-runner Specification

## Purpose

Gives the repository one short, discoverable entry point (`make <target>`) for linking the dotfiles, linting, and applying the Ansible profiles locally or to a remote VPS, without changing the scripts and playbooks it calls.

## Requirements

### Requirement: Self-documenting help
Running `make` with no target, or `make help`, SHALL print every public target with a one-line description and the supported variables, and SHALL make no changes to the system.

#### Scenario: Bare make
- **WHEN** the user runs `make` in the repo root
- **THEN** a list of targets (including `stow`, `unstow`, `restow`, `lint`, `arch`, `debian`, `ubuntu`, `vps`) with descriptions is printed, and nothing is linked, linted or provisioned

### Requirement: Works from any directory
Every target SHALL resolve paths from the Makefile's own location, so `make -C <repo> <target>` and `make -f <repo>/Makefile <target>` behave the same as running it in the repo root.

#### Scenario: Invoked from elsewhere
- **WHEN** the user runs `make -C ~/.void-dots stow` from their home directory
- **THEN** the repo's `stow.sh -s` runs and links from that clone

### Requirement: Linking targets wrap stow.sh
`make stow` SHALL run `stow.sh -s`, `make unstow` SHALL run `stow.sh -u`, and `make restow` SHALL run `stow.sh -u` followed by `stow.sh -s`, stopping if the first fails. Linking behaviour itself SHALL be exactly that of `stow.sh`.

#### Scenario: Restow
- **WHEN** the user runs `make restow`
- **THEN** the repo's symlinks are removed by `stow.sh -u` and then recreated by `stow.sh -s`

#### Scenario: Stow output unchanged
- **WHEN** every link is already correct and the user runs `make stow`
- **THEN** no create, backup or prune lines are printed, as with `stow.sh -s`

### Requirement: Dry-run linking
When `DRY=1` is given, the linking targets SHALL pass `-n` to every `stow.sh` call they make, so no symlink is created, moved or removed.

#### Scenario: Dry restow
- **WHEN** the user runs `make restow DRY=1`
- **THEN** `stow.sh -n -u` and `stow.sh -n -s` run and the filesystem is unchanged

### Requirement: Lint targets wrap lint.sh
`make lint` SHALL run `lint.sh` and `make lint-fix` SHALL run `lint.sh -w`, and each SHALL exit non-zero when `lint.sh` does.

#### Scenario: Lint failure propagates
- **WHEN** a tracked bash script has a shellcheck error and the user runs `make lint`
- **THEN** make reports failure with a non-zero exit status

### Requirement: Local profile targets
`make arch`, `make debian` and `make ubuntu` SHALL apply the `arch_desktop`, `debian_vps` and `ubuntu_vps` profiles to the current machine through the local inventory (hosts `local-arch`, `local-debian`, `local-ubuntu`), using the repo's `ansible/ansible.cfg` regardless of any `ANSIBLE_CONFIG` in the environment.

#### Scenario: Arch desktop run
- **WHEN** the user runs `make arch`
- **THEN** `ansible-playbook` applies `playbooks/arch_desktop.yml` limited to `local-arch` with the repo's `ansible.cfg`, prompting for the sudo password

#### Scenario: Builtin-only policy kept
- **WHEN** the user's shell exports `ANSIBLE_CONFIG` pointing elsewhere and runs `make debian`
- **THEN** the run still uses the repo's `ansible/ansible.cfg`

### Requirement: Privilege prompt for local runs
Local profile targets SHALL ask for the become password when run as a non-root user and SHALL NOT ask when run as root.

#### Scenario: Root on a VPS
- **WHEN** root runs `make debian TARGET_USER=deploy` on a Debian server
- **THEN** no become password prompt is shown

### Requirement: Remote VPS target
`make vps HOST=<host>` SHALL apply `playbooks/vps.yml` through `ansible/inventory/hosts.yml` limited to `<host>`. It SHALL fail before running Ansible, with a message naming the missing input, when `HOST` is empty or `hosts.yml` does not exist.

#### Scenario: Missing host
- **WHEN** the user runs `make vps` without `HOST`
- **THEN** make exits non-zero with a message asking for `HOST=<inventory host>` and Ansible is not started

#### Scenario: Missing remote inventory
- **WHEN** `ansible/inventory/hosts.yml` does not exist and the user runs `make vps HOST=my-debian-vps`
- **THEN** make exits non-zero and tells the user to copy `hosts.example.yml` to `hosts.yml`

### Requirement: Ansible run options
Every Ansible target SHALL accept `CHECK=1` (dry run with `--check`), `TAGS=<steps>` (`--tags`), `SKIP=<steps>` (`--skip-tags`), `TARGET_USER=<user>` (sets `void_target_user`) and `ARGS=<args>` (appended verbatim to `ansible-playbook`). Unset variables SHALL add nothing to the command.

#### Scenario: Dry run of selected steps
- **WHEN** the user runs `make arch CHECK=1 TAGS=aur,gaming`
- **THEN** `ansible-playbook` runs with `--check --tags aur,gaming` and changes nothing

#### Scenario: Passthrough arguments
- **WHEN** the user runs `make vps HOST=my-debian-vps ARGS="--ask-vault-pass -e swap_size=4G"`
- **THEN** both arguments are passed to `ansible-playbook` unchanged

### Requirement: Exit status follows the wrapped command
Each target SHALL exit with a non-zero status when the command it wraps fails, so targets can be chained and scripted.

#### Scenario: Failed playbook
- **WHEN** preflight fails during `make debian` because no target user was given
- **THEN** make exits non-zero
