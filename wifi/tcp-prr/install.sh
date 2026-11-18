#!/bin/bash
# Installs the boot service on macOS 27. Runs on Tahoe or on macOS 27.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
H="$(cd "$(dirname "$0")" && pwd)"
if [ "$(sw_vers -productVersion | cut -d. -f1)" = 27 ]; then R=""; else R="/Volumes/macOS 27 - Data"; fi
[ -z "$R" ] || [ -d "$R/Library/LaunchDaemons" ] || { echo "ERROR: $R not found"; exit 1; }
mkdir -p "$R/Library/TCPPRR"
install -o root -g wheel -m 755 "$H/tcp-prr-off.sh" "$R/Library/TCPPRR/tcp-prr-off.sh"
install -o root -g wheel -m 644 "$H/local.tcp-prr-off.plist" "$R/Library/LaunchDaemons/local.tcp-prr-off.plist"
if [ -z "$R" ]; then launchctl bootout system/local.tcp-prr-off 2>/dev/null || true; launchctl bootstrap system /Library/LaunchDaemons/local.tcp-prr-off.plist; fi
echo "Installed. Log: /var/log/tcp-prr-off.log"
