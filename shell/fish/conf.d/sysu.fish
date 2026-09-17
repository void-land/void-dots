set --query sysu_helper_commands || set --global sysu_helper_commands \
    "services:List all systemd service unit files" \
    "active:List active systemd services" \
    "failed:List failed systemd services" \
    "status:Show service status" \
    "start:Start a service" \
    "stop:Stop a service" \
    "restart:Restart a service" \
    "reload:Reload a service" \
    "enable:Enable a service at boot" \
    "disable:Disable a service from booting" \
    "enable-now:Enable and start a service immediately" \
    "disable-now:Disable and stop a service immediately" \
    "mask:Mask a service to prevent starting" \
    "unmask:Unmask a service" \
    "cat:Show service unit file configuration" \
    "edit:Edit service unit configuration" \
    "log:Show recent journal logs for a service" \
    "daemon-reload:Reload systemd manager configuration"
