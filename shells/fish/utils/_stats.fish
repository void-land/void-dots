function stats
    clear

    while true
        set rows (tput lines)
        set cols (tput cols)
        
        # Call the battery_status function to generate battery info
        set battery (battery_status)
        set text "$battery"
        set text_length (string length "$text")
        
        # Calculate vertical and horizontal centering
        set vert_center (math "floor($rows / 2)")
        set horiz_center (math "floor(($cols - $text_length) / 2)")
        
        # Clear screen and move cursor to center
        tput clear
        tput cup $vert_center $horiz_center
        
        # Print the battery status
        echo "$text"
        
        # Wait for 4 seconds
        sleep 4
    end
end

function battery_status
    if which termux-battery-status &>/dev/null
        set -l termux_bat_out (termux-battery-status)
        set bat_capacity (string match -rg 'percentage": ([0-9]*)' $termux_bat_out)
        set bat_status (string match -rg '"status": "([^"]*)"' $termux_bat_out)
    else if test -d /sys/class/power_supply/BAT0
        set bat_capacity (cat /sys/class/power_supply/BAT0/capacity)
        set bat_status (cat /sys/class/power_supply/BAT0/status)
        set voltage_now (cat /sys/class/power_supply/BAT0/voltage_now)
    else
        return
    end

    switch (string lower $bat_status)
        case charging
            set bat_status CHG
        case discharging
            set bat_status DIS
        case *
            set bat_status '??'
    end

    if [ $bat_capacity -lt 15 ]
        set_color red
    else if [ $bat_capacity -lt 30 ]
        set_color yellow
    else
        set_color green
    end

    # Convert microvolts to volts
    set voltage_v (math "$voltage_now / 1000000.0")

    printf "%s%% (%s) |" $bat_capacity $bat_status
    set_color normal
    printf " Voltage: %.2f V" $voltage_v
end
