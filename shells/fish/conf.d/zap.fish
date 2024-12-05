set --query ZAP_MIRROR || set --global ZAP_MIRROR "https://g.srev.in/get-appimage/index.min.json"
set --query ZAP_DATA_DIR || set --global ZAP_DATA_DIR $HOME/.local/share/zap
set --query ZAP_PACKAGES_LOCAL_INDEX || set --global ZAP_PACKAGES_LOCAL_INDEX $ZAP_DATA_DIR/.index
