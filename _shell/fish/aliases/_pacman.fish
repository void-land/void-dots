# ==============================================================================
# PACMAN ABBREVIATIONS (Prefix: fp)
# ==============================================================================

# Upgrades
abbr fpup 'sudo pacman -Syu'
abbr fpsync 'sudo pacman -Syyu'
abbr fpupdate 'sudo pacman -Sy'

# Install & Remove
abbr fpinstall 'sudo pacman -S'
abbr fpinstalllocal 'sudo pacman -U'
abbr fpremove 'sudo pacman -Rns'

# Searching
abbr fpsearch 'pacman -Ss'
abbr fpsearchfile 'pacman -F'
abbr fpsearchinstalled 'pacman -Qs'

# Information & Files
abbr fpinfo 'pacman -Si'
abbr fpinfoinstalled 'pacman -Qi'
abbr fpfiles 'pacman -Ql'

# Maintenance & Cleanup
abbr fporphans 'pacman -Qtdq'
abbr fpcleanorphans 'sudo pacman -Rns (pacman -Qtdq)'
abbr fpcleancache 'sudo pacman -Sc'
abbr fpcleancacheall 'sudo pacman -Scc'
