function myip --description 'Retrieve IP information using ip-api.com'
    set URL "http://ip-api.com/json/"

    check_command curl
    check_command jq

    echo "Fetching IP information from $URL"

    curl $URL -s | jq
end

function nmls --description 'List available Wi-Fi networks using nmcli'
    check_command nmcli

    echo "Scanning for available Wi-Fi networks..."

    nmcli device wifi list
end
