# ==============================================================================
# GAMESCOPE ABBREVIATIONS (Prefix: fg)
# ==============================================================================

# Downscale 8k -> 1080p
abbr fg8kto1080 'gamescope --mangoapp --force-grab-cursor -w 7680 -h 4320 -W 1920 -H 1080 -f --'

# Downscale 4k -> 1080p
abbr fg4kto1080 'gamescope --mangoapp --force-grab-cursor -w 3840 -h 2160 -W 1920 -H 1080 -f --'

# Downscale 2k -> 1080p
abbr fg2kto1080 'gamescope --mangoapp --force-grab-cursor -w 2560 -h 1440 -W 1920 -H 1080 -f -F fsr --'

# Upscale 900p -> 1080p
abbr fgup1080 'gamescope --mangoapp --force-grab-cursor -w 1600 -h 900 -W 1920 -H 1080 -f -F fsr --'

# Upscale 720p -> 1080p
abbr fgup720 'gamescope --mangoapp --force-grab-cursor -w 1280 -h 720 -W 1920 -H 1080 -f -F fsr --'
