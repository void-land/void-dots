# Short names for the repo's day-to-day commands. Run `make` for the list.
# Thin wrappers only: linking lives in stow.sh, linting in lint.sh,
# provisioning in ansible/. First-time setup is still bootstrap.sh.

SELF := $(lastword $(MAKEFILE_LIST))
REPO := $(abspath $(dir $(SELF)))

.DEFAULT_GOAL := help

# truthy VALUE — non-empty for 1/yes/true, so CHECK=0 or DRY=0 stay off.
truthy = $(filter 1 yes true,$(1))

# ─────────────────────────────────────────────
#  Options
# ─────────────────────────────────────────────

N := $(if $(call truthy,$(DRY)),-n)

# Always the repo's ansible.cfg (builtin-only policy), whatever the shell exports.
ANSIBLE_CONFIG := $(REPO)/ansible/ansible.cfg

# Local runs ask for the sudo password unless already root; BECOME= turns it off.
BECOME ?= $(if $(filter 0,$(shell id -u)),,-K)

ANSIBLE_OPTS = $(if $(call truthy,$(CHECK)),--check) \
	$(if $(TAGS),--tags $(TAGS)) \
	$(if $(SKIP),--skip-tags $(SKIP)) \
	$(if $(TARGET_USER),-e void_target_user=$(TARGET_USER)) \
	$(ARGS)

# playbook INVENTORY,HOST,PLAYBOOK — ansible-playbook run from ansible/
playbook = cd "$(REPO)/ansible" && ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" \
	ansible-playbook -i $(1) -l $(2) playbooks/$(3).yml

.PHONY: help stow unstow restow lint lint-fix arch debian ubuntu vps .require-host

##@ General

help: ## Show targets and variables
	@awk 'BEGIN { FS = ":.*## " } \
		/^##@/ { printf "\n%s\n", substr($$0, 5); next } \
		/^[a-z-]+:.*## / { printf "  %-10s %s\n", $$1, $$2 }' "$(SELF)"
	@printf '\n%s\n' "Variables"
	@printf '  %-14s %s\n' \
		"DRY=1" "stow targets: dry run (stow.sh -n)" \
		"CHECK=1" "ansible: dry run (--check)" \
		"TAGS=a,b" "ansible: only these steps (--tags)" \
		"SKIP=a,b" "ansible: skip these steps (--skip-tags)" \
		"TARGET_USER=u" "ansible: user to configure (void_target_user)" \
		"HOST=h" "vps: host from ansible/inventory/hosts.yml" \
		"BECOME=" "local ansible: don't ask for the sudo password" \
		"ARGS='...'" "ansible: extra ansible-playbook arguments"
	@printf '\n%s\n' "Example: make vps HOST=my-debian-vps CHECK=1 ARGS='--ask-vault-pass -e swap_size=4G'"

##@ Dotfiles

stow: ## Link dotfiles into ~ and ~/.config (stow.sh -s)
	"$(REPO)/stow.sh" $(N) -s

unstow: ## Remove the repo's symlinks (stow.sh -u)
	"$(REPO)/stow.sh" $(N) -u

restow: ## Unlink, then link again
	"$(REPO)/stow.sh" $(N) -u
	"$(REPO)/stow.sh" $(N) -s

##@ Lint

lint: ## Run lint.sh
	"$(REPO)/lint.sh"

lint-fix: ## Run lint.sh -w (apply shfmt)
	"$(REPO)/lint.sh" -w

##@ Ansible (this machine)

arch: ## Apply the arch_desktop profile here
	$(call playbook,inventory/local.yml,local-arch,arch_desktop) $(BECOME) $(ANSIBLE_OPTS)

debian: ## Apply the debian_vps profile here (needs TARGET_USER)
	$(call playbook,inventory/local.yml,local-debian,vps) $(BECOME) $(ANSIBLE_OPTS)

ubuntu: ## Apply the ubuntu_vps profile here (needs TARGET_USER)
	$(call playbook,inventory/local.yml,local-ubuntu,vps) $(BECOME) $(ANSIBLE_OPTS)

##@ Ansible (remote)

vps: .require-host ## Push the VPS profile to HOST over SSH
	@test -f "$(REPO)/ansible/inventory/hosts.yml" || { \
		echo "ansible/inventory/hosts.yml not found: cp ansible/inventory/hosts.example.yml ansible/inventory/hosts.yml and edit it." >&2; \
		exit 1; }
	$(call playbook,inventory/hosts.yml,$(HOST),vps) $(ANSIBLE_OPTS)

.require-host:
	$(if $(HOST),,$(error HOST is required: make vps HOST=<inventory host>))
