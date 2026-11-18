#!/bin/bash
# Removes the Wi-Fi service. Works on macOS 27 and, for the macOS 27 data volume, on Tahoe.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
if [ "$(sw_vers -productVersion | cut -d. -f1)" = 27 ]; then
  V=""; launchctl bootout system/local.wifi27-airportd 2>/dev/null || true
  pkill -f "launchctl debug system/com.apple.airportd" 2>/dev/null || true
else
  V="/Volumes/macOS 27 - Data"; [ -d "$V/Library/LaunchDaemons" ] || { echo "ERROR: $V is not mounted"; exit 1; }
fi
rm -f "$V/Library/LaunchDaemons/local.wifi27-airportd.plist"; rm -rf "$V/Library/WiFi27" "$V/Users/Shared/wifi27-oclp-fw"
echo "Removed. If AirportItlwm stays enabled, airportd crash-loops on macOS 27: also run sudo ./oc-wifi.sh 0 and restart."
