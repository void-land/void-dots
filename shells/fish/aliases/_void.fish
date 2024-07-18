alias void-pkgs="cd $VOID_PACKAGES_PATH"
alias vshutdown="sudo shutdown -h now"
alias vreboot="sudo reboot"
alias vrepos="xbps-query -L"
alias vpkgf="xbps-query -f"
alias vpkg="sudo xbps-install -S"
alias vup="sudo xbps-install -Su"
alias vrm="sudo xbps-remove -R"
alias vsearch="xbps-query -Rs"
alias vinfo="xbps-query -S"
alias vlocate="xbps-query -f"
alias vlist="xbps-query -l"
alias vhold="sudo xbps-pkgdb -m hold"
alias vunhold="sudo xbps-pkgdb -m unhold"
alias vmirror="sudo xmirror"
alias killall="pkill -f"
alias vcp="sudo xbps-remove -O"
alias vch="echo 'Clean: all cache packages' && sudo rm /var/cache/xbps/*"
alias svservices="ls /etc/sv/"
alias svlist="ls -la /var/service/"
alias svreset="sudo sv restart"
alias svstatus="sudo sv status"
alias svon="sudo sv up"
alias svoff="sudo sv down"