#!/usr/bin/env bash
# bootstrap.sh — one-line provisioning entry point for void-dots.
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/void-land/void-dots/main/bootstrap.sh)"
#
# Detects the distro, installs git + ansible-core (never Galaxy content),
# clones or fast-forwards the repo, lets you exclude steps with the same
# yay-style picker as the rest of the repo, then applies the matching Ansible
# profile (ansible/playbooks/*) to this machine.

set -uo pipefail

REPO_URL="${VOID_REPO_URL:-https://github.com/void-land/void-dots.git}"
REPO_BRANCH="main"
REPO_DEST="$HOME/.void-dots"
VENV_DIR="$HOME/.local/share/void-dots/ansible-venv"
VENV_SPEC="ansible-core>=2.17,<2.18"
MIN_ANSIBLE="2.14"
OS_RELEASE="${VOID_OS_RELEASE:-/etc/os-release}" # overridable for testing
SUPPORTED="Arch Linux (and derivatives such as EndeavourOS), Debian 12+, Ubuntu 22.04+"

PROFILE=""
ASSUME_YES=false
CHECK=false
TAGS=""
SKIP_TAGS=""
TARGET_USER=""
EXTRA_ARGS=()
PASSTHRU=()

FAMILY="" # pacman | apt
DISTRO_ID=""
SUDO=()        # privilege prefix for prerequisite installs
BECOME_ARGS=() # ansible-playbook privilege flags
ANSIBLE_BIN=""
TMP_DIR=""

# If run from a clone, default to that clone instead of ~/.void-dots.
SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$SELF" && -f "$SELF" ]]; then
	SELF_DIR="$(cd "$(dirname "$SELF")" && pwd)"
	[[ -f "$SELF_DIR/ansible/ansible.cfg" ]] && REPO_DEST="$SELF_DIR"
fi

# ─────────────────────────────────────────────
#  Helpers (scripts-lib.sh isn't available until the repo is cloned)
# ─────────────────────────────────────────────

info() { echo "[*] $*"; }
success() { echo "[✓] $*"; }
warn() { echo "[!] $*" >&2; }
die() {
	echo "[✗] $*" >&2
	exit 1
}

usage() {
	cat <<EOF
Usage: bootstrap.sh [-p <profile>] [-y] [-n] [-t <steps>] [-x <steps>] [-u <user>]
                    [-e <var=value>]... [-d <dir>] [-b <branch>] [-h] [-- <ansible-playbook args>]

Detects the distro, installs git + ansible-core, clones/updates the repo and
applies the matching provisioning profile to this machine.

 -p <profile>  arch_desktop | debian_vps | ubuntu_vps (default: detected)
 -y            Unattended: no pickers or prompts, defaults everywhere
 -n            Dry run (ansible-playbook --check)
 -t <steps>    Only run these steps (comma-separated step ids)
 -x <steps>    Skip these steps (comma-separated step ids)
 -u <user>     Target non-root user (VPS: sudo user to create/configure)
 -e <var=val>  Extra Ansible variable (repeatable), e.g. -e swap_size=4G
 -d <dir>      Repo clone location (default: ~/.void-dots, or this clone)
 -b <branch>   Repo branch (default: main)
 -h            Show this help
 -- <args>     Pass the remaining arguments to ansible-playbook unchanged

Supported: $SUPPORTED.
EOF
}

cleanup() {
	[[ -t 0 ]] && stty echo 2>/dev/null
	[[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT
trap 'echo; warn "Interrupted."; exit 130' INT TERM

# version_ge A B — true if version A >= B
version_ge() {
	[[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

# ansible_version BIN — prints the core version of an ansible-playbook binary
ansible_version() {
	"$1" --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1
}

contains() {
	local needle="$1" item
	shift
	for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
	return 1
}

# ─────────────────────────────────────────────
#  Detection and prerequisites
# ─────────────────────────────────────────────

detect_distro() {
	[[ -r "$OS_RELEASE" ]] || die "$OS_RELEASE not found, can't detect the distribution."
	local id id_like
	# shellcheck source=/dev/null
	id=$(. "$OS_RELEASE" && echo "${ID:-}")
	# shellcheck source=/dev/null
	id_like=$(. "$OS_RELEASE" && echo "${ID_LIKE:-}")
	DISTRO_ID="$id"

	local detected=""
	if [[ "$id" == "arch" || " $id_like " == *" arch "* ]]; then
		FAMILY=pacman detected=arch_desktop
	elif [[ "$id" == "debian" ]]; then
		FAMILY=apt detected=debian_vps
	elif [[ "$id" == "ubuntu" ]]; then
		FAMILY=apt detected=ubuntu_vps
	fi

	if [[ -z "$PROFILE" ]]; then
		[[ -n "$detected" ]] || die "Unsupported distribution: ${id:-unknown}. Supported: $SUPPORTED."
		PROFILE="$detected"
	fi
	case "$PROFILE" in
	arch_desktop | debian_vps | ubuntu_vps) ;;
	*) die "Unknown profile '$PROFILE' (use arch_desktop, debian_vps or ubuntu_vps)." ;;
	esac
}

check_privileges() {
	if [[ "$PROFILE" == "arch_desktop" ]]; then
		[[ $EUID -ne 0 ]] || die "Run the Arch desktop profile as your regular user, not root (it asks for sudo itself)."
		command -v sudo &>/dev/null || die "sudo is required."
		SUDO=(sudo)
		BECOME_ARGS=(--ask-become-pass)
	elif [[ $EUID -eq 0 ]]; then
		SUDO=()
		BECOME_ARGS=()
	else
		command -v sudo &>/dev/null || die "Run as root, or install sudo for this user."
		SUDO=(sudo)
		if sudo -n true 2>/dev/null; then
			BECOME_ARGS=()
		else
			BECOME_ARGS=(--ask-become-pass)
		fi
	fi
}

ansible_ok() {
	local v
	[[ -x "$1" ]] || return 1
	v=$(ansible_version "$1")
	[[ -n "$v" ]] && version_ge "$v" "$MIN_ANSIBLE"
}

install_venv_ansible() {
	info "Installing $VENV_SPEC into $VENV_DIR..."
	python3 -m venv "$VENV_DIR" || die "Couldn't create a Python venv (is python3-venv installed?)."
	"$VENV_DIR/bin/pip" install --quiet --upgrade pip || die "pip couldn't upgrade itself in $VENV_DIR."
	"$VENV_DIR/bin/pip" install --quiet "$VENV_SPEC" || die "pip couldn't install $VENV_SPEC."
}

install_prereqs() {
	local sys_bin
	sys_bin=$(command -v ansible-playbook 2>/dev/null || true)

	case "$FAMILY" in
	pacman)
		local need=()
		command -v git &>/dev/null || need+=(git)
		command -v python3 &>/dev/null || need+=(python)
		[[ -n "$sys_bin" ]] && ansible_ok "$sys_bin" || need+=(ansible-core)
		if ((${#need[@]})); then
			info "Installing ${need[*]}..."
			"${SUDO[@]}" pacman -S --needed --noconfirm "${need[@]}" || die "pacman failed (try 'sudo pacman -Syu' first)."
		fi
		;;
	apt)
		local need=() pkg
		for pkg in git python3 python3-venv openssl ca-certificates; do
			dpkg -s "$pkg" &>/dev/null || need+=("$pkg")
		done
		if ((${#need[@]})) || ! { [[ -n "$sys_bin" ]] && ansible_ok "$sys_bin"; }; then
			info "Refreshing apt cache..."
			"${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive apt-get update -qq || die "apt-get update failed."
		fi
		if ((${#need[@]})); then
			info "Installing ${need[*]}..."
			"${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${need[@]}" || die "apt-get install failed."
		fi
		if ! { [[ -n "$sys_bin" ]] && ansible_ok "$sys_bin"; } && ! ansible_ok "$VENV_DIR/bin/ansible-playbook"; then
			local candidate
			candidate=$(apt-cache policy ansible-core 2>/dev/null | awk '/Candidate:/ {print $2}' | grep -oE '^[0-9]+\.[0-9]+(\.[0-9]+)?')
			if [[ -n "$candidate" ]] && version_ge "$candidate" "$MIN_ANSIBLE"; then
				info "Installing ansible-core $candidate from the distribution..."
				"${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ansible-core || die "apt-get install ansible-core failed."
			else
				warn "Distribution ansible-core (${candidate:-none}) is older than $MIN_ANSIBLE."
				install_venv_ansible
			fi
		fi
		;;
	*)
		# Unknown distro with an explicit -p: only proceed if everything is already there.
		if ! command -v git &>/dev/null || [[ -z "$sys_bin" ]] || ! ansible_ok "$sys_bin"; then
			die "Unsupported distribution: ${DISTRO_ID:-unknown}. Supported: $SUPPORTED."
		fi
		warn "Unsupported distribution ${DISTRO_ID:-unknown}; using the installed git and ansible-core."
		;;
	esac

	sys_bin=$(command -v ansible-playbook 2>/dev/null || true)
	if [[ -n "$sys_bin" ]] && ansible_ok "$sys_bin"; then
		ANSIBLE_BIN="$(dirname "$sys_bin")"
	elif ansible_ok "$VENV_DIR/bin/ansible-playbook"; then
		ANSIBLE_BIN="$VENV_DIR/bin"
	else
		die "No ansible-core >= $MIN_ANSIBLE available after installation."
	fi
	info "Using ansible-core $(ansible_version "$ANSIBLE_BIN/ansible-playbook") from $ANSIBLE_BIN"
}

sync_repo() {
	if [[ -d "$REPO_DEST/.git" ]]; then
		if [[ -n "$(git -C "$REPO_DEST" status --porcelain 2>/dev/null)" ]]; then
			warn "$REPO_DEST has local changes; not updating it, running from the current tree."
		elif [[ "$(git -C "$REPO_DEST" rev-parse --abbrev-ref HEAD 2>/dev/null)" != "$REPO_BRANCH" ]]; then
			warn "$REPO_DEST is not on '$REPO_BRANCH'; not updating it, running from the current tree."
		else
			info "Updating $REPO_DEST..."
			git -C "$REPO_DEST" pull --ff-only --quiet ||
				warn "Couldn't fast-forward $REPO_DEST; running from the current tree."
		fi
	elif [[ -e "$REPO_DEST" ]]; then
		die "$REPO_DEST exists but isn't a git clone; move it away or pass -d <dir>."
	else
		info "Cloning $REPO_URL ($REPO_BRANCH) into $REPO_DEST..."
		git clone --quiet --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DEST" || die "git clone failed."
	fi
	[[ -f "$REPO_DEST/ansible/ansible.cfg" ]] || die "$REPO_DEST has no ansible/ directory (wrong repo or branch?)."
	info "Running from $(git -C "$REPO_DEST" log -1 --format='%h %s (%cr)')"
}

# ─────────────────────────────────────────────
#  Step selection and inputs
# ─────────────────────────────────────────────

ANSIBLE_DIR=""
INVENTORY=""
INV_HOST=""
PLAYBOOK=""
declare -a STEP_IDS=() STEP_DESCS=() GROUP_NAMES=() GROUP_LABELS=()
declare -a SELECTED=() EXCLUDED_GROUPS=()

load_profile() {
	ANSIBLE_DIR="$REPO_DEST/ansible"
	INVENTORY="$ANSIBLE_DIR/inventory/local.yml"
	case "$PROFILE" in
	arch_desktop) INV_HOST=local-arch PLAYBOOK="$ANSIBLE_DIR/playbooks/arch_desktop.yml" ;;
	debian_vps) INV_HOST=local-debian PLAYBOOK="$ANSIBLE_DIR/playbooks/vps.yml" ;;
	ubuntu_vps) INV_HOST=local-ubuntu PLAYBOOK="$ANSIBLE_DIR/playbooks/vps.yml" ;;
	esac

	export ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg"
	local json line
	json=$("$ANSIBLE_BIN/ansible-inventory" -i "$INVENTORY" --host "$INV_HOST" 2>/dev/null) ||
		die "Couldn't read the $PROFILE profile from $INVENTORY."
	while IFS=$'\t' read -r kind a b; do
		case "$kind" in
		step) STEP_IDS+=("$a") STEP_DESCS+=("$b") ;;
		group) GROUP_NAMES+=("$a") GROUP_LABELS+=("$b") ;;
		esac
	done < <(python3 -c '
import json, sys
d = json.load(sys.stdin)
for s in d.get("void_profile_steps", []):
    print("\t".join(["step", s["id"], s["desc"]]))
for g in d.get("packages_groups", []):
    pk = g["packages"]
    more = ", ..." if len(pk) > 4 else ""
    label = "%s (%d: %s%s)" % (g["name"], len(pk), ", ".join(pk[:4]), more)
    print("\t".join(["group", g["name"], label]))
' <<<"$json")
	((${#STEP_IDS[@]})) || die "The $PROFILE profile defines no steps."

	for line in "${GROUP_NAMES[@]}"; do
		[[ "$line" =~ ^[a-z0-9_-]+$ ]] || die "Invalid package group name '$line' in the profile."
	done
}

# split_csv CSV — prints one item per line
split_csv() { tr ',' '\n' <<<"$1" | sed '/^$/d'; }

# can_prompt: questions are allowed (not -y, stdin is a terminal).
can_prompt() { [[ "$ASSUME_YES" != true && -t 0 ]]; }

select_steps() {
	local id i pickers=false
	local -a only=() skip=()
	# Pickers only when steps weren't already chosen on the command line.
	can_prompt && [[ -z "$TAGS" && -z "$SKIP_TAGS" ]] && pickers=true
	mapfile -t only < <(split_csv "$TAGS")
	mapfile -t skip < <(split_csv "$SKIP_TAGS")
	for id in "${only[@]}" "${skip[@]}"; do
		contains "$id" "${STEP_IDS[@]}" || die "Unknown step '$id' for $PROFILE (steps: ${STEP_IDS[*]})."
	done

	if [[ "$pickers" == true ]]; then
		# shellcheck source=dotfiles/scripts/scripts-lib.sh
		source "$REPO_DEST/dotfiles/scripts/scripts-lib.sh"
		echo
		local -A excluded=()
		select_exclusions STEP_DESCS "steps" excluded
		for i in "${!STEP_IDS[@]}"; do
			[[ -n "${excluded[$((i + 1))]:-}" ]] && skip+=("${STEP_IDS[$i]}")
		done
	fi

	SELECTED=()
	for id in "${STEP_IDS[@]}"; do
		((${#only[@]})) && ! contains "$id" "${only[@]}" && continue
		((${#skip[@]})) && contains "$id" "${skip[@]}" && continue
		SELECTED+=("$id")
	done
	((${#SELECTED[@]})) || die "No steps selected."
	SKIP_TAGS=$(
		IFS=,
		echo "${skip[*]}"
	)

	if [[ "$pickers" == true ]] && contains packages "${SELECTED[@]}" && ((${#GROUP_NAMES[@]})); then
		echo
		local -A excluded_groups=()
		select_exclusions GROUP_LABELS "package groups" excluded_groups
		for i in "${!GROUP_NAMES[@]}"; do
			[[ -n "${excluded_groups[$((i + 1))]:-}" ]] && EXCLUDED_GROUPS+=("${GROUP_NAMES[$i]}")
		done
	fi
}

prompt_target_user() {
	local default="" input
	[[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]] && default="$SUDO_USER"
	[[ $EUID -ne 0 ]] && default="$USER"
	while true; do
		read -rp "Target (non-root) user${default:+ [$default]}: " input
		input="${input:-$default}"
		if [[ -z "$input" ]]; then
			echo "A username is required."
		elif [[ "$input" == "root" ]]; then
			echo "Pick a non-root user."
		elif [[ ! "$input" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
			echo "Invalid username (lowercase letters, digits, '_' and '-')."
		else
			TARGET_USER="$input"
			return
		fi
	done
}

SWAP_SIZE=""
TIMEZONE=""
PASSWORD_HASH=""

prompt_inputs() {
	local needs_user=false id
	for id in user docker shell dotfiles; do
		contains "$id" "${SELECTED[@]}" && needs_user=true
	done

	can_prompt || return 0

	if [[ "$PROFILE" != "arch_desktop" && "$needs_user" == true && -z "$TARGET_USER" ]]; then
		prompt_target_user
	fi

	if contains swap "${SELECTED[@]}" && [[ -z "$(swapon --show --noheadings 2>/dev/null)" ]]; then
		local input
		while true; do
			read -rp "Swapfile size (e.g. 1G, 2G, 512M) [2G]: " input
			input="${input:-2G}"
			[[ "$input" =~ ^[0-9]+[MG]$ ]] && break
			echo "Use a number followed by M or G."
		done
		SWAP_SIZE="$input"
	fi

	if contains timezone "${SELECTED[@]}"; then
		local current input
		current=$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)
		current="${current:-UTC}"
		while true; do
			read -rp "Timezone (e.g. Asia/Tehran, UTC) [$current]: " input
			input="${input:-$current}"
			[[ "$input" =~ ^[A-Za-z0-9_+-]+(/[A-Za-z0-9_+-]+)*$ && -f "/usr/share/zoneinfo/$input" ]] && break
			echo "Unknown timezone: $input"
		done
		TIMEZONE="$input"
	fi

	if contains user "${SELECTED[@]}" && [[ -n "$TARGET_USER" ]] && ! id "$TARGET_USER" &>/dev/null; then
		local pw pw2
		echo "User '$TARGET_USER' will be created. Choose a password (needed for sudo):"
		while true; do
			read -rsp "Password: " pw
			echo
			read -rsp "Repeat password: " pw2
			echo
			if [[ -z "$pw" ]]; then
				echo "The password can't be empty."
			elif [[ "$pw" != "$pw2" ]]; then
				echo "Passwords don't match."
			else
				break
			fi
		done
		PASSWORD_HASH=$(printf '%s' "$pw" | openssl passwd -6 -stdin) || die "openssl couldn't hash the password."
		unset pw pw2
	fi
}

# write_vars_file — collected inputs as JSON, passed with -e @file. Values are
# validated above, so they need no JSON escaping. Holds the password hash, so
# it lives in a private temp dir removed on exit.
write_vars_file() {
	local -a entries=()
	[[ -n "$TARGET_USER" ]] && entries+=("\"void_target_user\": \"$TARGET_USER\"")
	[[ -n "$SWAP_SIZE" ]] && entries+=("\"swap_size\": \"$SWAP_SIZE\"")
	[[ -n "$TIMEZONE" ]] && entries+=("\"timezone_name\": \"$TIMEZONE\"")
	[[ -n "$PASSWORD_HASH" ]] && entries+=("\"user_password_hash\": \"$PASSWORD_HASH\"")
	if ((${#EXCLUDED_GROUPS[@]})); then
		local g list=""
		for g in "${EXCLUDED_GROUPS[@]}"; do list+="${list:+, }\"$g\""; done
		entries+=("\"packages_exclude_groups\": [$list]")
	fi
	((${#entries[@]})) || return 0

	TMP_DIR=$(umask 077 && mktemp -d) || die "mktemp failed."
	local IFS=,
	(umask 077 && printf '{%s}\n' "${entries[*]}" >"$TMP_DIR/vars.json")
	EXTRA_ARGS+=(-e "@$TMP_DIR/vars.json")
}

# ─────────────────────────────────────────────
#  Run
# ─────────────────────────────────────────────

run_playbook() {
	local -a cmd=("$ANSIBLE_BIN/ansible-playbook" -i "$INVENTORY" -l "$INV_HOST" "$PLAYBOOK")
	cmd+=("${BECOME_ARGS[@]}")
	[[ "$CHECK" == true ]] && cmd+=(--check)
	[[ -n "$TAGS" ]] && cmd+=(--tags "$TAGS")
	[[ -n "$SKIP_TAGS" ]] && cmd+=(--skip-tags "$SKIP_TAGS")
	cmd+=("${EXTRA_ARGS[@]}" "${PASSTHRU[@]}")

	mkdir -p "$HOME/.cache/void-dots"
	export ANSIBLE_LOG_PATH="$HOME/.cache/void-dots/ansible.log"

	echo
	info "Profile: $PROFILE$([[ "$CHECK" == true ]] && echo " (dry run)")"
	info "Steps:   ${SELECTED[*]}"
	((${#EXCLUDED_GROUPS[@]})) && info "Skipping package groups: ${EXCLUDED_GROUPS[*]}"
	info "Running: ${cmd[*]}"
	echo

	"${cmd[@]}"
	local rc=$?
	if ((rc != 0)); then
		warn "ansible-playbook failed (exit $rc). Log: $ANSIBLE_LOG_PATH"
		exit "$rc"
	fi
	if [[ "$CHECK" == true ]]; then
		success "Dry run finished; nothing was changed."
	else
		success "Provisioning finished. Log out and back in (or reboot) so shell, group and service changes take effect."
	fi
}

# ─────────────────────────────────────────────
#  Main
# ─────────────────────────────────────────────

while getopts "p:ynt:x:u:e:d:b:h" opt; do
	case $opt in
	p) PROFILE="$OPTARG" ;;
	y) ASSUME_YES=true ;;
	n) CHECK=true ;;
	t) TAGS="$OPTARG" ;;
	x) SKIP_TAGS="$OPTARG" ;;
	u) TARGET_USER="$OPTARG" ;;
	e) EXTRA_ARGS+=(-e "$OPTARG") ;;
	d) REPO_DEST="$OPTARG" ;;
	b) REPO_BRANCH="$OPTARG" ;;
	h)
		usage
		exit 0
		;;
	*)
		usage
		exit 1
		;;
	esac
done
shift $((OPTIND - 1))
PASSTHRU=("$@")

if [[ -n "$TARGET_USER" && ("$TARGET_USER" == "root" || ! "$TARGET_USER" =~ ^[a-z_][a-z0-9_-]*$) ]]; then
	die "Invalid target user: $TARGET_USER"
fi

detect_distro
check_privileges
install_prereqs
sync_repo
load_profile
select_steps
prompt_inputs
write_vars_file
run_playbook
