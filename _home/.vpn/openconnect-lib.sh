#!/usr/bin/env bash
# openconnect-lib.sh — Reusable OpenConnect VPN helper library
# Source this file; do not execute it directly.
#
# Usage:
#   source /path/to/openconnect-lib.sh
#
# Server Configuration (Define in environment or wrapper script):
#   TciProfiles=(
#       "TCI.apibaz.org"
#       "TCIS1.apibaz.org"
#       "TCIS2.apibaz.org"
#       "TCIS3.apibaz.org"
#       "TCIS4.apibaz.org"
#   )
#   MciProfiles="mci1.apibaz.org,mci2.apibaz.org"
#
# Optional environment variables:
#   VPN_PROFILES_ORDER   — category variable names to control display order
#   VPN_USER             — OpenConnect username
#   VPN_PASSWORD         — OpenConnect password
#   VPN_AUTH_FILE        — path to an existing auth file (user on line 1, pass on line 2)
#   VPN_EXTRA_ARGS       — extra arguments forwarded verbatim to openconnect (default: --no-dtls)
#   VPN_AUTO_ACCEPT_CERT — auto-confirm untrusted certificate prompt with "yes" (default: true)

# Guard against being executed instead of sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo "ERROR: openconnect-lib.sh must be sourced, not executed." >&2
	echo "  source $(basename "${BASH_SOURCE[0]}")" >&2
	exit 1
fi

# ---------------------------------------------------------------------------
# Internal state & helpers
# ---------------------------------------------------------------------------
declare -a _VPN_FLAT_NAMES=()
declare -a _VPN_FLAT_HOSTS=()
declare -a _VPN_FLAT_CATS=()

_vpn_add_server() {
	local entry="$1" cat="$2"
	entry="$(echo "$entry" | xargs)"
	[[ -z "$entry" ]] && return

	local name="$entry" host="$entry"
	if [[ "$entry" =~ ^([^:=]+)[=:]([a-zA-Z0-9_.-]+(:[0-9]+)?)$ ]] && [[ ! "${BASH_REMATCH[1]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		name="$(echo "${BASH_REMATCH[1]}" | xargs)"
		host="$(echo "${BASH_REMATCH[2]}" | xargs)"
	fi

	_VPN_FLAT_NAMES+=("$name")
	_VPN_FLAT_HOSTS+=("$host")
	_VPN_FLAT_CATS+=("$cat")
}

_vpn_add_category_items() {
	local cat="$1"
	local -n ref="$cat" 2>/dev/null || return
	local items=()

	if [[ "$(declare -p "$cat" 2>/dev/null)" =~ "declare -a" ]]; then
		items=("${ref[@]}")
	else
		IFS=',' read -ra items <<< "$ref"
	fi

	for item in "${items[@]}"; do
		local subitems=()
		IFS=',' read -ra subitems <<< "$item"
		for s in "${subitems[@]}"; do
			_vpn_add_server "$s" "$cat"
		done
	done
}

_vpn_build_server_index() {
	_VPN_FLAT_NAMES=()
	_VPN_FLAT_HOSTS=()
	_VPN_FLAT_CATS=()

	# 1. Category arrays / strings (TciProfiles, MciProfiles, etc.)
	local cat_vars=()
	if [[ -n "${VPN_PROFILES_ORDER+x}" && ${#VPN_PROFILES_ORDER[@]} -gt 0 ]]; then
		cat_vars=("${VPN_PROFILES_ORDER[@]}")
	else
		mapfile -t cat_vars < <(compgen -v | grep -iE '(profiles|_profiles)$' | sort)
	fi

	for var in "${cat_vars[@]}"; do
		[[ "$var" =~ ^(VPN_SERVERS|VPN_CATEGORIES|VPN_CATEGORY_ORDER|VPN_SERVER_ORDER|VPN_PROFILES_ORDER)$ ]] && continue
		[[ -v "$var" ]] && _vpn_add_category_items "$var"
	done

	# 2. Explicit VPN_CATEGORIES map
	if [[ -n "${VPN_CATEGORIES+x}" && ${#VPN_CATEGORIES[@]} -gt 0 ]]; then
		local cats=()
		if [[ -n "${VPN_CATEGORY_ORDER+x}" && ${#VPN_CATEGORY_ORDER[@]} -gt 0 ]]; then
			cats=("${VPN_CATEGORY_ORDER[@]}")
		else
			mapfile -t cats < <(printf '%s\n' "${!VPN_CATEGORIES[@]}" | sort)
		fi
		for cat in "${cats[@]}"; do
			local items=()
			IFS=',' read -ra items <<< "${VPN_CATEGORIES[$cat]:-}"
			for item in "${items[@]}"; do
				_vpn_add_server "$item" "$cat"
			done
		done
	fi

	# 3. Flat VPN_SERVERS map
	if [[ -n "${VPN_SERVERS+x}" && ${#VPN_SERVERS[@]} -gt 0 ]]; then
		local srv_order=()
		if [[ -n "${VPN_SERVER_ORDER+x}" && ${#VPN_SERVER_ORDER[@]} -gt 0 ]]; then
			srv_order=("${VPN_SERVER_ORDER[@]}")
		else
			mapfile -t srv_order < <(printf '%s\n' "${!VPN_SERVERS[@]}" | sort)
		fi
		for name in "${srv_order[@]}"; do
			local host="${VPN_SERVERS[$name]}"
			[[ -n "$host" ]] && _vpn_add_server "$name=$host" "General"
		done
	fi
}

# ---------------------------------------------------------------------------
# vpn_list_servers
#   Print a numbered list of available VPN servers grouped by category.
# ---------------------------------------------------------------------------
vpn_list_servers() {
	_vpn_build_server_index

	if [[ ${#_VPN_FLAT_HOSTS[@]} -eq 0 ]]; then
		echo "ERROR: No VPN servers or profiles configured." >&2
		echo "Please define category profiles (e.g. TciProfiles=(...)), VPN_CATEGORIES, or VPN_SERVERS." >&2
		return 1
	fi

	echo -e "\nAvailable OpenConnect VPN Servers:"
	local current_cat=""

	for i in "${!_VPN_FLAT_HOSTS[@]}"; do
		local cat="${_VPN_FLAT_CATS[$i]:-}"
		if [[ -n "$cat" && "$cat" != "$current_cat" ]]; then
			current_cat="$cat"
			echo -e "\n  ─── $cat ──────────────────────────────────────────"
		fi
		local name="${_VPN_FLAT_NAMES[$i]}"
		local host="${_VPN_FLAT_HOSTS[$i]}"
		if [[ "$name" != "$host" ]]; then
			printf "  %2d)  %-28s (%s)\n" "$((i + 1))" "$name" "$host"
		else
			printf "  %2d)  %s\n" "$((i + 1))" "$host"
		fi
	done
	echo ""
}

# ---------------------------------------------------------------------------
# vpn_select_server [prompt]
#   Interactively prompt the user to pick a VPN server.
#   Accepts server index, profile name, or direct hostname.
# ---------------------------------------------------------------------------
vpn_select_server() {
	local prompt="${1:-Select a VPN server (number or host): }"
	_vpn_build_server_index

	if [[ ${#_VPN_FLAT_HOSTS[@]} -eq 0 ]]; then
		echo "ERROR: No VPN servers or profiles configured." >&2
		return 1
	fi

	local input
	while true; do
		read -rp "$prompt" input
		input="$(echo "$input" | xargs)"
		[[ -z "$input" ]] && continue

		# 1. Numeric selection (1..N)
		if [[ "$input" =~ ^[0-9]+$ ]] && ((input >= 1 && input <= ${#_VPN_FLAT_HOSTS[@]})); then
			echo "${_VPN_FLAT_HOSTS[$((input - 1))]}"
			return 0
		fi

		# 2. Exact or case-insensitive profile name / host / prefix match
		for i in "${!_VPN_FLAT_HOSTS[@]}"; do
			local host="${_VPN_FLAT_HOSTS[$i]}"
			local name="${_VPN_FLAT_NAMES[$i]}"
			local host_pfx="${host%%.*}"
			if [[ "${input,,}" == "${name,,}" || "${input,,}" == "${host,,}" || "${input,,}" == "${host_pfx,,}" ]]; then
				echo "$host"
				return 0
			fi
		done

		# 3. Direct hostname or IP address entered by user
		if [[ "$input" =~ \. ]]; then
			echo "$input"
			return 0
		fi

		echo "Invalid selection. Please enter a valid number or host." >&2
	done
}

# ---------------------------------------------------------------------------
# _vpn_resolve_auth
#   Resolves username and password from VPN_AUTH_FILE or VPN_USER/VPN_PASSWORD.
# ---------------------------------------------------------------------------
_vpn_resolve_auth() {
	if [[ -n "${VPN_AUTH_FILE:-}" ]]; then
		if [[ ! -f "$VPN_AUTH_FILE" ]]; then
			echo "ERROR: VPN_AUTH_FILE not found: $VPN_AUTH_FILE" >&2
			return 1
		fi
		_RESOLVED_USER="$(sed -n '1p' "$VPN_AUTH_FILE" | tr -d '\r\n')"
		_RESOLVED_PASSWORD="$(sed -n '2p' "$VPN_AUTH_FILE" | tr -d '\r\n')"
		return 0
	fi

	_RESOLVED_USER="${VPN_USER:-${USER:-}}"
	_RESOLVED_PASSWORD="${VPN_PASSWORD:-${PASSWORD:-}}"

	[[ -z "$_RESOLVED_USER" ]] && read -rp "VPN Username: " _RESOLVED_USER
	if [[ -z "$_RESOLVED_PASSWORD" ]]; then
		read -rsp "VPN Password: " _RESOLVED_PASSWORD
		echo "" >&2
	fi

	if [[ -z "$_RESOLVED_USER" || -z "$_RESOLVED_PASSWORD" ]]; then
		echo "ERROR: Both username and password are required." >&2
		return 1
	fi
}

# ---------------------------------------------------------------------------
# vpn_connect <server_or_profile_or_index>
#   Connect using OpenConnect to the specified server.
# ---------------------------------------------------------------------------
vpn_connect() {
	local target="$1"
	if [[ -z "$target" ]]; then
		echo "ERROR: vpn_connect requires a server address, profile name, or index." >&2
		return 1
	fi

	_vpn_build_server_index
	local server=""

	# 1. Number index
	if [[ "$target" =~ ^[0-9]+$ ]] && ((target >= 1 && target <= ${#_VPN_FLAT_HOSTS[@]})); then
		server="${_VPN_FLAT_HOSTS[$((target - 1))]}"
	fi

	# 2. Match name or host
	if [[ -z "$server" ]]; then
		for i in "${!_VPN_FLAT_HOSTS[@]}"; do
			if [[ "${target,,}" == "${_VPN_FLAT_NAMES[$i],,}" || "${target,,}" == "${_VPN_FLAT_HOSTS[$i],,}" ]]; then
				server="${_VPN_FLAT_HOSTS[$i]}"
				break
			fi
		done
	fi

	server="${server:-$target}"

	local _RESOLVED_USER="" _RESOLVED_PASSWORD=""
	_vpn_resolve_auth || return 1

	local label="${VPN_AUTH_FILE:+auth file $(basename "$VPN_AUTH_FILE")}"
	label="${label:-user '$_RESOLVED_USER'}"
	echo "Connecting to OpenConnect VPN at $server using $label..."

	local extra_args="${VPN_EXTRA_ARGS:---no-dtls}"

	if [[ "${VPN_AUTO_ACCEPT_CERT:-true}" == "true" ]]; then
		# shellcheck disable=SC2086
		printf '%s\n%s\n' "yes" "$_RESOLVED_PASSWORD" | sudo openconnect \
			--server="$server" \
			--user="$_RESOLVED_USER" \
			$extra_args
	else
		# shellcheck disable=SC2086
		printf '%s\n' "$_RESOLVED_PASSWORD" | sudo openconnect \
			--server="$server" \
			--user="$_RESOLVED_USER" \
			--passwd-on-stdin \
			$extra_args
	fi

	return $?
}

# ---------------------------------------------------------------------------
# vpn_connect_interactive
#   One-shot helper: list servers by category → prompt selection → connect.
# ---------------------------------------------------------------------------
vpn_connect_interactive() {
	vpn_list_servers || return 1
	local selected
	selected="$(vpn_select_server)" || return 1
	vpn_connect "$selected"
}
