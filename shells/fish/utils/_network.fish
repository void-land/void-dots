function myip --description 'Retrieve IP information using ip-api.com'
    set URL "https://api.myip.com/"

    check_command curl
    check_command jq

    echo "Fetching IP information from $URL"

    curl $URL -s | jq
end

function myinterfaces --description 'Display full details for physical, VPN, and tunnel network interfaces using nmcli'
    # Ensure nmcli is installed before running
    if not command -v nmcli >/dev/null
        set_color red
        echo "Error: 'nmcli' (NetworkManager) is not installed or not in PATH." >&2
        set_color normal
        return 1
    end

    # Fetch and loop through matching interfaces
    # Filters for: ethernet, wifi, vpn, tun, and wireguard
    set -l devices (nmcli -t -f DEVICE,TYPE device | grep -E 'ethernet|wifi|vpn|tun|wireguard' | cut -d: -f1)

    if test -z "$devices"
        set_color yellow
        echo "No active physical, VPN, or tunnel interfaces found."
        set_color normal
        return 0
    end

    for dev in $devices
        set_color --bold cyan
        echo "=== Interface: $dev ==="
        set_color normal

        nmcli device show "$dev"
        echo ""
    end
end
