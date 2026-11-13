# Spec Delta

## Purpose

Defines the self-contained Ansible project that provisions every supported machine profile: its builtin-only module policy, the profile and variable model, the contract every reusable role follows, and the lint checks that keep it that way.

## ADDED Requirements

### Requirement: Builtin-only module policy
Every task in the Ansible project SHALL use either an `ansible.builtin.*` module (by its fully-qualified name) or a module shipped inside the repository. The project MUST NOT depend on Ansible Galaxy roles or collections and MUST NOT ship a `requirements.yml`.

#### Scenario: Run on a controller that has the full `ansible` package installed
- **WHEN** a playbook is run on a machine where third-party collections (e.g. `community.general`) are installed system-wide
- **THEN** the project's configuration prevents those collections from being resolved, and the run uses only builtin and repository-local modules

#### Scenario: A task references a third-party module
- **WHEN** a task file references a module outside `ansible.builtin.*` and the repository-local module set
- **THEN** the repository lint check fails and names the offending file and module

### Requirement: Repository-local modules cover missing builtins
The project SHALL provide its own modules for operations `ansible-core` has no builtin for: Arch repository package management (install, remove, sync databases, full upgrade) and AUR package build/install. Each local module SHALL support check mode, SHALL report `changed` only when the system was altered, and SHALL return the affected package names.

#### Scenario: Installing already-present packages
- **WHEN** the package module is asked to ensure packages that are all already installed
- **THEN** it reports `changed: false` and runs no install transaction

#### Scenario: Check mode with missing packages
- **WHEN** the package module runs in check mode and some requested packages are missing
- **THEN** it reports `changed: true`, lists the packages it would install, and installs nothing

#### Scenario: Unknown package name
- **WHEN** a requested package does not exist in any enabled repository (or, for AUR, on the AUR)
- **THEN** the module fails with a message naming the unknown package

### Requirement: Profiles map to inventory groups and playbooks
The project SHALL define the profiles `arch_desktop`, `debian_vps` and `ubuntu_vps` as inventory groups, with `debian_vps` and `ubuntu_vps` both children of a `vps` group. Each profile SHALL be runnable from its own playbook, and a `site.yml` SHALL run the correct profile for every host in an inventory.

#### Scenario: Running site.yml against a mixed inventory
- **WHEN** `site.yml` runs against an inventory containing one Arch desktop host and one Ubuntu VPS host
- **THEN** each host receives only the roles of its own profile

### Requirement: Layered profile variables
Profile behaviour (package groups, services, users, feature toggles) SHALL be data in `group_vars` and overridable per host, with precedence `all` < `vps` < distro profile < `host_vars` < extra vars. Roles SHALL ship safe defaults so that a role runs with no profile variables set.

#### Scenario: Overriding a package group per host
- **WHEN** a host's `host_vars` excludes a package group defined in its profile
- **THEN** that host's run skips that group while other hosts of the same profile still install it

### Requirement: Local inventory targets the current machine
The project SHALL ship a committed local inventory that defines one localhost entry per profile using a local connection, so any profile can be applied to the machine running Ansible by limiting to that entry.

#### Scenario: Applying a profile locally
- **WHEN** a playbook is run with the local inventory limited to the `ubuntu_vps` local entry on an Ubuntu machine
- **THEN** Ansible connects locally without SSH and applies the `ubuntu_vps` profile to that machine

### Requirement: Remote inventory is user-supplied and untracked
The project SHALL ship a committed example remote inventory, and the real remote inventory file and any host-specific secret files SHALL be ignored by git.

#### Scenario: Creating a remote inventory
- **WHEN** the user copies the example remote inventory to the real inventory path and adds a VPS host
- **THEN** `git status` does not show the new inventory file

### Requirement: Preflight validation
Every profile run SHALL first validate that the target's distribution matches the profile, that `ansible-core` meets the minimum supported version, and that required variables are set and valid, and SHALL fail before making any change if a check fails.

#### Scenario: Wrong distro for profile
- **WHEN** the `arch_desktop` profile is run against a Debian host
- **THEN** the run fails in preflight with a message naming the detected distribution and the expected one, and no other task runs on that host

#### Scenario: Missing required variable
- **WHEN** a VPS profile runs without a target user configured
- **THEN** the run fails in preflight with a message naming the missing variable

### Requirement: Step tags
Every provisioning step SHALL be selectable and skippable by an Ansible tag whose name is the step id, and preflight SHALL run regardless of tag selection.

#### Scenario: Running a single step
- **WHEN** a profile playbook is run with `--tags docker`
- **THEN** only preflight and the Docker step run

#### Scenario: Skipping a step
- **WHEN** a profile playbook is run with `--skip-tags aur`
- **THEN** every step except the AUR step runs

### Requirement: Idempotent and check-mode safe roles
Every role SHALL be idempotent: a second consecutive run with the same inputs SHALL report zero changed tasks. Every role SHALL run under `--check` without modifying the target, and SHALL not fail in check mode solely because an earlier step would have made a change.

#### Scenario: Second run
- **WHEN** a profile is applied twice in a row to the same machine with the same variables, and no upstream package updates or repository commits appeared in between
- **THEN** the second run's recap shows `changed=0`

#### Scenario: Dry run on a fresh machine
- **WHEN** a profile is run with `--check` on a freshly installed machine
- **THEN** the run completes, reports what would change, and the machine's packages, files and services are unchanged afterwards

### Requirement: Secrets are not logged
Tasks that handle passwords, password hashes or other secrets SHALL suppress their arguments and results from output and logs.

#### Scenario: Setting a user's password hash
- **WHEN** a role sets a user password from a supplied hash
- **THEN** neither the console output nor the Ansible log file contains the hash

### Requirement: Repository lint covers the Ansible project
`./lint.sh` SHALL syntax-check every playbook, byte-compile every repository-local module, run the builtin-only check, and run `ansible-lint` when it is installed (skipping it with a notice otherwise), and SHALL exit non-zero if any check fails.

#### Scenario: Lint with a playbook syntax error
- **WHEN** a playbook contains invalid YAML and `./lint.sh` runs
- **THEN** lint reports the playbook as failing and exits non-zero

#### Scenario: ansible-lint not installed
- **WHEN** `ansible-lint` is not on `PATH` and `./lint.sh` runs
- **THEN** lint prints that it skipped ansible-lint and still runs the other Ansible checks
