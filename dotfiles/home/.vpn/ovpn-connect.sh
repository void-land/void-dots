#!/usr/bin/env bash
# ovpn-connect.sh — Interactive OpenVPN connector (uses ovpn-lib.sh)
#
# Usage:
#   ./ovpn-connect.sh [options]
#
# Options:
#   -d DIR        Directory containing .ovpn files
#                 (required unless -c is a path to a .ovpn file)
#   -u USER       VPN username             (ignored when -f is used)
#   -p PASS       VPN password             (ignored when -f is used)
#   -f AUTH_FILE  Path to auth file        (user on line 1, password on line 2)
#                 Without -f/-u/-p, openvpn prompts for credentials itself.
#   -c CONFIG     Skip interactive prompt; connect directly to this config
#                 (name inside -d DIR, or a path to any .ovpn file)
#   -e ARGS       Extra arguments forwarded verbatim to openvpn
#   -h            Show this help
#
# Environment variables (lower priority than flags):
#   VPN_CONFIG_DIR, VPN_USER, VPN_PASSWORD, VPN_AUTH_FILE, VPN_EXTRA_ARGS
#
# Examples:
#   # Interactive — inline credentials
#   ./ovpn-connect.sh -d ~/.vpn/ovpn-servers/vpnbaz -u username -p password
#
#   # Interactive — file-based auth
#   ./ovpn-connect.sh -d ~/.vpn/ovpn-servers/vpnbaz -f ~/.vpn/auth.txt
#
#   # Non-interactive — jump straight to a specific server
#   ./ovpn-connect.sh -d ~/.vpn/ovpn-servers/vpnbaz -f ~/.vpn/auth.txt -c "us-east.ovpn"
#
#   # One-off config from anywhere (openvpn asks for the credentials)
#   ./ovpn-connect.sh -c ~/Downloads/nl-free-34.protonvpn.tcp.ovpn

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate and source the library (same directory as this script)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="$SCRIPT_DIR/ovpn-lib.sh"

if [[ ! -f "$LIB_FILE" ]]; then
	echo "ERROR: Cannot find ovpn-lib.sh alongside this script ($SCRIPT_DIR)." >&2
	exit 1
fi

# shellcheck source=./ovpn-lib.sh
source "$LIB_FILE"

# ---------------------------------------------------------------------------
# Parse flags
# ---------------------------------------------------------------------------
_direct_config=""

usage() {
	sed -n '/^# Usage/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \{0,1\}//'
	exit 0
}

(($# == 0)) && usage

while getopts ":d:u:p:f:c:e:h" opt; do
	case "$opt" in
	d) VPN_CONFIG_DIR="$OPTARG" ;;
	u) VPN_USER="$OPTARG" ;;
	p) VPN_PASSWORD="$OPTARG" ;;
	f) VPN_AUTH_FILE="$OPTARG" ;;
	c) _direct_config="$OPTARG" ;;
	e) VPN_EXTRA_ARGS="$OPTARG" ;;
	h) usage ;;
	:)
		echo "ERROR: -$OPTARG requires an argument." >&2
		exit 1
		;;
	\?)
		echo "ERROR: Unknown option -$OPTARG." >&2
		exit 1
		;;
	esac
done

# Export so sub-functions in the library see them
export VPN_CONFIG_DIR VPN_USER VPN_PASSWORD VPN_AUTH_FILE VPN_EXTRA_ARGS

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [[ -n "$_direct_config" && -f "$_direct_config" ]]; then
	# Non-interactive: an existing file path is used as-is, no config dir needed.
	vpn_connect "$_direct_config"
	exit
fi

if [[ -z "${VPN_CONFIG_DIR:-}" ]]; then
	echo "ERROR: No config directory; pass -d DIR, or -c with a path to a .ovpn file." >&2
	echo "Run with -h for help." >&2
	exit 1
fi

vpn_load_configs "$VPN_CONFIG_DIR"

if [[ -n "$_direct_config" ]]; then
	# Non-interactive: resolve the supplied name/path to a full path.
	resolved=""
	for f in "${_VPN_OVPN_FILES[@]}"; do
		fname="$(basename "$f")"
		if [[ "$_direct_config" == "$f" || "$_direct_config" == "$fname" ||
			"$_direct_config" == "${fname%.ovpn}" ]]; then
			resolved="$f"
			break
		fi
	done

	if [[ -z "$resolved" ]]; then
		echo "ERROR: Config not found: $_direct_config" >&2
		exit 1
	fi

	vpn_connect "$resolved"
else
	# Interactive mode
	vpn_list_configs
	selected="$(vpn_select_config)"
	vpn_connect "$selected"
fi
