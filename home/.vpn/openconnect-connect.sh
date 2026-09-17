#!/usr/bin/env bash
# openconnect-connect.sh — Interactive OpenConnect VPN connector (uses openconnect-lib.sh)
#
# Usage:
#   ./openconnect-connect.sh [options]
#
# Options:
#   -s SERVER     Skip interactive prompt; connect directly to this server (name or host)
#   -u USER       VPN username             (ignored when -f is used)
#   -p PASS       VPN password             (ignored when -f is used)
#   -f AUTH_FILE  Path to auth file        (user on line 1, password on line 2)
#   -e ARGS       Extra arguments forwarded verbatim to openconnect (default: --no-dtls)
#   -l            List available servers and exit
#   -h            Show this help
#
# Environment variables (lower priority than flags):
#   VPN_USER, VPN_PASSWORD, VPN_AUTH_FILE, VPN_EXTRA_ARGS
#
# Examples:
#   # Interactive selection
#   ./openconnect-connect.sh -f ~/.vpn/ovpn-servers/vpnbaz.auth
#
#   # Non-interactive direct connect
#   ./openconnect-connect.sh -f ~/.vpn/ovpn-servers/vpnbaz.auth -s "NL 11"
#   ./openconnect-connect.sh -u myuser -p mypass -s "nl11.apibaz.info"

set -euo pipefail

# ---------------------------------------------------------------------------
# Locate and source the library (same directory as this script)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_FILE="$SCRIPT_DIR/openconnect-lib.sh"

if [[ ! -f "$LIB_FILE" ]]; then
	echo "ERROR: Cannot find openconnect-lib.sh alongside this script ($SCRIPT_DIR)." >&2
	exit 1
fi

# shellcheck source=./openconnect-lib.sh
source "$LIB_FILE"

# ---------------------------------------------------------------------------
# Parse flags
# ---------------------------------------------------------------------------
_direct_server=""
_list_only=false

usage() {
	sed -n '/^# Usage/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \{0,1\}//'
	exit 0
}

while getopts ":s:u:p:f:e:lh" opt; do
	case "$opt" in
		s) _direct_server="$OPTARG" ;;
		u) VPN_USER="$OPTARG" ;;
		p) VPN_PASSWORD="$OPTARG" ;;
		f) VPN_AUTH_FILE="$OPTARG" ;;
		e) VPN_EXTRA_ARGS="$OPTARG" ;;
		l) _list_only=true ;;
		h) usage ;;
		:) echo "ERROR: -$OPTARG requires an argument." >&2; exit 1 ;;
		\?) echo "ERROR: Unknown option -$OPTARG." >&2; exit 1 ;;
	esac
done

# Export so sub-functions in the library see them
export VPN_USER VPN_PASSWORD VPN_AUTH_FILE VPN_EXTRA_ARGS

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [[ "$_list_only" == true ]]; then
	vpn_list_servers
	exit 0
fi

if [[ -n "$_direct_server" ]]; then
	vpn_connect "$_direct_server"
else
	vpn_connect_interactive
fi
