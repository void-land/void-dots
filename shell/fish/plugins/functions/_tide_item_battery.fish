function _tide_item_battery
  if which termux-battery-status &>/dev/null
    set -l termux_bat_out (termux-battery-status)
    set bat_capacity (string match -rg 'percentage": ([0-9]*)' $termux_bat_out)
    set bat_status (string match -rg '"status": "([^"]*)"' $termux_bat_out)
  else if test -d /sys/class/power_supply/BAT0
    set bat_capacity (cat /sys/class/power_supply/BAT0/capacity)
    set bat_status (cat /sys/class/power_supply/BAT0/status)
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
  printf "%s%%" $bat_capacity
  set_color normal
  printf " (%s)" $bat_status
end
