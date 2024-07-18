function wget_speed --description 'Perform a speed test using wget'
    check_command wget

    echo "WGET Speedtest"

    echo "URL $SPEEDTEST_DOWNLOAD_URL"

    wget -q --show-progress --progress=bar -O /dev/null $SPEEDTEST_DOWNLOAD_URL
end
