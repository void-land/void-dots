#!/usr/bin/env python3

# ─────────────────────────────────────────────
#  DNS Switcher
# ─────────────────────────────────────────────

import os
import sys
import subprocess
import shutil
from datetime import datetime

# ─────────────────────────────────────────────
#  DNS Profiles
# ─────────────────────────────────────────────

DNS_SERVERS: dict[str, list[str]] = {
    "LOCAL":      ["127.0.0.1"],
    "MCI":        ["10.185.68.113", "10.185.68.114"],
    "SHECAN":     ["178.22.122.100", "185.51.200.2"],
    "SHECAN PRO": ["178.22.122.100", "185.51.200.2"],
    "GOOGLE":     ["8.8.8.8", "8.8.4.4"],
    "CF":         ["1.1.1.1"],
}

RESOLV_CONF = "/etc/resolv.conf"

# ─────────────────────────────────────────────
#  Logging helpers
# ─────────────────────────────────────────────

def info(msg: str)    -> None: print(f"[*] {msg}")
def success(msg: str) -> None: print(f"[✓] {msg}")
def warn(msg: str)    -> None: print(f"[!] {msg}", file=sys.stderr)
def die(msg: str)     -> None:
    print(f"[✗] {msg}", file=sys.stderr)
    sys.exit(1)

# ─────────────────────────────────────────────
#  Root check
# ─────────────────────────────────────────────

def require_root() -> None:
    if os.geteuid() == 0:
        return
    info("Re-launching with root privileges...")
    os.execvp("sudo", ["sudo", sys.executable] + sys.argv)

# ─────────────────────────────────────────────
#  Display & Selection
# ─────────────────────────────────────────────

def display_dns_list() -> None:
    print("\n  Available DNS Servers")
    print("  ──────────────────────────────────────")
    for i, (name, ips) in enumerate(DNS_SERVERS.items(), start=1):
        ip_str = ", ".join(ips)
        print(f"  {i:2d}.  {name:<14}  {ip_str}")
    print("  ──────────────────────────────────────\n")


def select_dns() -> str:
    names = list(DNS_SERVERS.keys())
    while True:
        raw = input("  Select DNS (name or number): ").strip()

        # Numeric selection
        if raw.isdigit():
            idx = int(raw) - 1
            if 0 <= idx < len(names):
                return names[idx]

        # Name selection (case-insensitive)
        elif raw.upper() in DNS_SERVERS:
            return raw.upper()

        warn("Invalid selection, try again.")

# ─────────────────────────────────────────────
#  resolv.conf management
# ─────────────────────────────────────────────

def is_immutable(path: str) -> bool:
    try:
        result = subprocess.run(
            ["lsattr", path],
            capture_output=True, text=True
        )
        attrs = result.stdout.split()[0] if result.stdout.strip() else ""
        return "i" in attrs
    except Exception:
        return False


def prepare_resolv_conf() -> None:
    # Replace symlink with a real file
    if os.path.islink(RESOLV_CONF):
        info(f"{RESOLV_CONF} is a symlink — replacing with a real file...")
        os.remove(RESOLV_CONF)

    # Create if missing
    if not os.path.exists(RESOLV_CONF):
        info(f"{RESOLV_CONF} not found — creating...")
        try:
            open(RESOLV_CONF, "w").close()
        except OSError as e:
            die(f"Cannot create {RESOLV_CONF}: {e}")

    # Unlock if immutable
    if is_immutable(RESOLV_CONF):
        info(f"Unlocking {RESOLV_CONF}...")
        result = subprocess.run(["chattr", "-i", RESOLV_CONF])
        if result.returncode != 0:
            die(f"Failed to unlock {RESOLV_CONF}.")


def write_resolv_conf(name: str, ips: list[str]) -> None:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines = [
        f"# dns-switcher — profile: {name}",
        f"# updated: {timestamp}",
        "",
        "search .",
        "",
        *[f"nameserver {ip}" for ip in ips],
    ]
    try:
        with open(RESOLV_CONF, "w") as f:
            f.write("\n".join(lines) + "\n")
    except OSError as e:
        die(f"Failed to write {RESOLV_CONF}: {e}")


def lock_resolv_conf() -> None:
    result = subprocess.run(["chattr", "+i", RESOLV_CONF])
    if result.returncode != 0:
        die(f"Failed to lock {RESOLV_CONF}.")
    info(f"Locked {RESOLV_CONF}.")

# ─────────────────────────────────────────────
#  nmcli — detect active connection
# ─────────────────────────────────────────────

def get_active_connection() -> str | None:
    try:
        result = subprocess.run(
            ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show", "--active"],
            capture_output=True, text=True
        )
        for line in result.stdout.splitlines():
            parts = line.split(":")
            if len(parts) >= 3 and parts[1] != "loopback" and parts[2] == "activated":
                return parts[0]
    except FileNotFoundError:
        pass
    return None


def apply_nmcli_dns(conn: str | None, ips: list[str]) -> None:
    if not shutil.which("nmcli"):
        warn("nmcli not found — skipping NetworkManager update.")
        return

    if not conn:
        warn("No active NetworkManager connection found — skipping nmcli update.")
        return

    dns_str = " ".join(ips)
    info(f"Applying DNS to NetworkManager connection: '{conn}'...")

    # Set DNS
    r = subprocess.run(["nmcli", "connection", "modify", conn, "ipv4.dns", dns_str])
    if r.returncode != 0:
        die(f"nmcli: failed to set DNS on '{conn}'.")

    # Prevent DHCP from overriding DNS
    r = subprocess.run(["nmcli", "connection", "modify", conn, "ipv4.ignore-auto-dns", "yes"])
    if r.returncode != 0:
        warn("nmcli: could not set ignore-auto-dns (non-fatal).")

    # Restart the connection
    info(f"Restarting connection '{conn}'...")
    subprocess.run(["nmcli", "connection", "down", conn])   # may fail if already down — non-fatal
    r = subprocess.run(["nmcli", "connection", "up", conn])
    if r.returncode != 0:
        die(f"nmcli: failed to bring up '{conn}'.")

    success("NetworkManager updated and connection restarted.")

# ─────────────────────────────────────────────
#  Apply
# ─────────────────────────────────────────────

def apply_dns(name: str) -> None:
    ips = DNS_SERVERS[name]

    # ── resolv.conf ──
    prepare_resolv_conf()
    write_resolv_conf(name, ips)
    lock_resolv_conf()

    # ── nmcli ──
    conn = get_active_connection()
    apply_nmcli_dns(conn, ips)

    print()
    success(f"Applied '{name}' → {', '.join(ips)}")
    if conn:
        success(f"Interface '{conn}' updated and restarted.")

    print(f"\n  {RESOLV_CONF} now contains:")
    print("  ──────────────────────────────────────")
    try:
        with open(RESOLV_CONF) as f:
            for line in f:
                print(f"  {line}", end="")
    except OSError as e:
        warn(f"Could not read {RESOLV_CONF}: {e}")
    print("\n  ──────────────────────────────────────\n")

# ─────────────────────────────────────────────
#  Main
# ─────────────────────────────────────────────

def main() -> None:
    require_root()
    display_dns_list()
    name = select_dns()
    apply_dns(name)


if __name__ == "__main__":
    main()