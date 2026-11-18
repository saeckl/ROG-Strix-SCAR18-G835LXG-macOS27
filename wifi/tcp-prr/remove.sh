#!/bin/bash
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
if [ "$(sw_vers -productVersion | cut -d. -f1)" = 27 ]; then R=""; launchctl bootout system/local.tcp-prr-off 2>/dev/null || true; else R="/Volumes/macOS 27 - Data"; fi
rm -f "$R/Library/LaunchDaemons/local.tcp-prr-off.plist"; rm -rf "$R/Library/TCPPRR"; echo "Removed."
