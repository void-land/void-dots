# ==============================================================================
# ZRAM ABBREVIATIONS (Prefix: zr)
# ==============================================================================

# Device detail & compression stats
abbr zr "zramctl --output NAME,ALGORITHM,DISKSIZE,DATA,COMPR,TOTAL,COMP-RATIO,ZERO-PAGES,MEM-USED,MOUNTPOINT"
abbr zra "zramctl --output-all"
abbr zrw "watch -n1 zramctl --output NAME,ALGORITHM,DISKSIZE,DATA,COMPR,TOTAL,COMP-RATIO,MEM-USED"
abbr zrswap "swapon --show"
abbr zrlog "sudo dmesg | grep -iE 'zram|zswap'"

# void-zram profiles
abbr zrs "void-zram -s"
abbr zrl "void-zram -l"
abbr zrstd "void-zram -p standard"
abbr zrgame "void-zram -p gaming"
