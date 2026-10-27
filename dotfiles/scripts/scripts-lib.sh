#!/usr/bin/env bash
# scripts-lib.sh — shared helpers for scripts/
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

# ─────────────────────────────────────────────
#  Pickers
# ─────────────────────────────────────────────

# Generic yay-style exclude picker.
# Usage: select_exclusions <name-of-input-array-var> <label> <name-of-output-array-var>
# Prints a numbered list of the given array's elements, prompts once for
# items to exclude (accepts "1 2 3", "1-3", "^4", space/comma separated,
# "^" prefix optional), and writes the 1-based excluded indices into the
# caller-supplied output array (nameref) - no global state involved, so
# nested calls (a picker inside a step chosen by another picker) can never
# clobber a different call's result.
select_exclusions() {
	local -n items_ref="$1"
	local label="${2:-items}"
	local -n out_ref="$3"
	local i token excl_input

	echo -e "${C_BLUE}::${C_NC} Following $label will be executed:"
	for i in "${!items_ref[@]}"; do
		printf "%2d  %s\n" "$((i + 1))" "${items_ref[$i]}"
	done
	echo -e "${C_BLUE}==>${C_NC} ${label^} to exclude: (eg: \"1 2 3\", \"1-3\", \"^4\")"
	echo -e "${C_RED} -> Excluding $label may result in a partial setup${C_NC}"
	read -rp "==> " excl_input

	out_ref=()
	if [[ -n "$excl_input" ]]; then
		# normalize commas to spaces so both styles work
		excl_input="${excl_input//,/ }"
		for token in $excl_input; do
			token="${token#^}"
			if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
				for ((i = "${BASH_REMATCH[1]}"; i <= "${BASH_REMATCH[2]}"; i++)); do
					out_ref[$i]=1
				done
			elif [[ "$token" =~ ^[0-9]+$ ]]; then
				out_ref[$token]=1
			fi
		done
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

# Shared color vars (select_exclusions, void-arch-setup, void-steam-prefixes).
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_NC='\033[0m'
