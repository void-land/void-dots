#!/usr/bin/env bash
# scripts-lib.sh — shared helpers for home/.scripts/
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/scripts-lib.sh"
# (script-relative, not $HOME-relative: require_root's `sudo bash "$0"`
#  re-exec resets $HOME to /root, which would break a $HOME-based path)

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo "ERROR: scripts-lib.sh must be sourced, not executed." >&2
	echo "  source $(basename "${BASH_SOURCE[0]}")" >&2
	exit 1
fi

info() { echo "[*] $*"; }
success() { echo "[✓] $*"; }
warn() { echo "[!] $*" >&2; }
die() {
	echo "[✗] $*" >&2
	exit 1
}

require_root() {
	[[ $EUID -eq 0 ]] && return
	info "Re-launching with root privileges..."
	exec sudo bash "$0" "$@"
}

# confirm PROMPT [DEFAULT]
#   DEFAULT "n" (default) shows [y/N], only "y" continues.
#   DEFAULT "y" shows [Y/n], only "n" aborts.
confirm() {
	local prompt="$1" default="${2:-n}" ans suffix="[y/N]"
	[[ "$default" == "y" ]] && suffix="[Y/n]"
	read -rp "  ${prompt} ${suffix}: " ans
	ans="${ans,,}"
	if [[ "$default" == "y" ]]; then
		[[ "$ans" == "n" ]] && return 1
		return 0
	else
		[[ "$ans" == "y" ]] && return 0
		return 1
	fi
}

# warn_box MESSAGE — prints the boxed "⚠ MESSAGE" warning banner
warn_box() {
	local msg="$1" width=40
	echo ""
	printf "  ╔%s╗\n" "$(printf '═%.0s' $(seq 1 "$width"))"
	printf "  ║  ⚠  %-*s║\n" "$((width - 5))" "$msg"
	printf "  ╚%s╝\n" "$(printf '═%.0s' $(seq 1 "$width"))"
	echo ""
}

# Shared color vars, only currently used by void-steam-prefixes.
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_NC='\033[0m'
