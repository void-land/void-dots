#!/usr/bin/env bash
# vpn-lib.sh — Reusable OpenVPN helper library
# Source this file; do not execute it directly.
#
# Usage:
#   source /path/to/ovpn-lib.sh
#
# Optional environment variables (set before sourcing or before calling functions):
#   VPN_CONFIG_DIR   — directory containing .ovpn files
#                      (default: $HOME/.scripts/ovpn-vpnbaz-servers)
#   VPN_USER         — OpenVPN username            (used for inline auth)
#   VPN_PASSWORD     — OpenVPN password            (used for inline auth)
#   VPN_AUTH_FILE    — path to an existing auth file (user on line 1, pass on line 2)
#                      When set, VPN_USER / VPN_PASSWORD are ignored.
#   VPN_EXTRA_ARGS   — extra arguments forwarded verbatim to openvpn

# Guard against being executed instead of sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: vpn-lib.sh must be sourced, not executed." >&2
    echo "  source $(basename "${BASH_SOURCE[0]}")" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------
declare -a _VPN_OVPN_FILES=()
_VPN_TEMP_AUTH_FILE=""        # path of a temp creds file we created (so we can clean it up)

# ---------------------------------------------------------------------------
# vpn_load_configs [dir]
#   Populate _VPN_OVPN_FILES from DIR (defaults to VPN_CONFIG_DIR).
#   Returns 0 on success, 1 if no files found.
# ---------------------------------------------------------------------------
vpn_load_configs() {
    local dir="${1:-${VPN_CONFIG_DIR:-$HOME/.scripts/ovpn-vpnbaz-servers}}"

    if [[ ! -d "$dir" ]]; then
        echo "ERROR: Config directory not found: $dir" >&2
        return 1
    fi

    mapfile -t _VPN_OVPN_FILES < <(find "$dir" -maxdepth 1 -type f -name "*.ovpn" | sort)

    if [[ ${#_VPN_OVPN_FILES[@]} -eq 0 ]]; then
        echo "ERROR: No .ovpn files found in $dir" >&2
        return 1
    fi
}

# ---------------------------------------------------------------------------
# vpn_list_configs
#   Print a numbered list of loaded .ovpn files.
# ---------------------------------------------------------------------------
vpn_list_configs() {
    if [[ ${#_VPN_OVPN_FILES[@]} -eq 0 ]]; then
        echo "No configs loaded. Call vpn_load_configs first." >&2
        return 1
    fi

    echo "Available OpenVPN configuration files:"
    local i=1
    for f in "${_VPN_OVPN_FILES[@]}"; do
        printf "  %d) %s\n" "$i" "$(basename "$f")"
        ((i++))
    done
}

# ---------------------------------------------------------------------------
# vpn_select_config [prompt]
#   Interactively prompt the user to pick a config.
#   Prints the full path of the selected file to stdout.
# ---------------------------------------------------------------------------
vpn_select_config() {
    local prompt="${1:-Select a config file (number or filename): }"

    if [[ ${#_VPN_OVPN_FILES[@]} -eq 0 ]]; then
        echo "ERROR: No configs loaded. Call vpn_load_configs first." >&2
        return 1
    fi

    local input
    while true; do
        read -rp "$prompt" input

        # Numeric selection
        if [[ $input =~ ^[0-9]+$ ]]; then
            if ((input >= 1 && input <= ${#_VPN_OVPN_FILES[@]})); then
                echo "${_VPN_OVPN_FILES[$((input - 1))]}"
                return 0
            fi
        else
            # Match by filename (with or without .ovpn extension)
            for f in "${_VPN_OVPN_FILES[@]}"; do
                local fname
                fname="$(basename "$f")"
                if [[ "$input" == "$fname" || "$input" == "${fname%.ovpn}" ]]; then
                    echo "$f"
                    return 0
                fi
            done
        fi

        echo "Invalid selection. Please try again." >&2
    done
}

# ---------------------------------------------------------------------------
# _vpn_resolve_auth_file
#   Internal helper.
#   Resolves which auth file to use and sets _VPN_TEMP_AUTH_FILE if a
#   temporary one was created.
#   Prints the path of the auth file to stdout.
# ---------------------------------------------------------------------------
_vpn_resolve_auth_file() {
    # 1. Caller supplied an explicit auth file — use it as-is.
    if [[ -n "${VPN_AUTH_FILE:-}" ]]; then
        if [[ ! -f "$VPN_AUTH_FILE" ]]; then
            echo "ERROR: VPN_AUTH_FILE not found: $VPN_AUTH_FILE" >&2
            return 1
        fi
        echo "$VPN_AUTH_FILE"
        return 0
    fi

    # 2. Inline credentials — write a temporary file.
    if [[ -z "${VPN_USER:-}" || -z "${VPN_PASSWORD:-}" ]]; then
        echo "ERROR: Set VPN_AUTH_FILE, or both VPN_USER and VPN_PASSWORD." >&2
        return 1
    fi

    local tmp
    tmp="$(mktemp)"
    chmod 600 "$tmp"
    printf '%s\n%s\n' "$VPN_USER" "$VPN_PASSWORD" > "$tmp"

    _VPN_TEMP_AUTH_FILE="$tmp"
    echo "$tmp"
}

# ---------------------------------------------------------------------------
# _vpn_cleanup
#   Remove the temporary auth file if we created one.
# ---------------------------------------------------------------------------
_vpn_cleanup() {
    if [[ -n "$_VPN_TEMP_AUTH_FILE" && -f "$_VPN_TEMP_AUTH_FILE" ]]; then
        rm -f "$_VPN_TEMP_AUTH_FILE"
        _VPN_TEMP_AUTH_FILE=""
    fi
}

# ---------------------------------------------------------------------------
# vpn_connect <config_file>
#   Connect using the given .ovpn file.
#   Honours VPN_AUTH_FILE (file-based auth) or VPN_USER+VPN_PASSWORD (inline).
#   Extra openvpn flags can be passed via VPN_EXTRA_ARGS.
# ---------------------------------------------------------------------------
vpn_connect() {
    local config_file="$1"

    if [[ -z "$config_file" ]]; then
        echo "ERROR: vpn_connect requires a config file path." >&2
        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        echo "ERROR: Config file not found: $config_file" >&2
        return 1
    fi

    local auth_file
    auth_file="$(_vpn_resolve_auth_file)" || return 1

    local label="${VPN_AUTH_FILE:+file-based auth}"
    label="${label:-user '$VPN_USER'}"
    echo "Connecting to $(basename "$config_file") using $label ..."

    # shellcheck disable=SC2086
    sudo openvpn \
        --config    "$config_file" \
        --auth-user-pass "$auth_file" \
        ${VPN_EXTRA_ARGS:-}

    local exit_code=$?
    _vpn_cleanup
    return "$exit_code"
}

# ---------------------------------------------------------------------------
# vpn_connect_interactive [config_dir]
#   One-shot helper: load configs → list → prompt → connect.
# ---------------------------------------------------------------------------
vpn_connect_interactive() {
    local dir="${1:-}"
    vpn_load_configs ${dir:+"$dir"} || return 1
    vpn_list_configs
    local selected
    selected="$(vpn_select_config)" || return 1
    vpn_connect "$selected"
}