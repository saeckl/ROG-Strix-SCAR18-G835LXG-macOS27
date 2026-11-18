#!/bin/bash
# Enables the Wi-Fi kexts for Darwin 27 in the OpenCore config of the macOS 27 disk, step by step.
#   sudo ./oc-wifi.sh 3     all parts on (target state)      sudo ./oc-wifi.sh 0     back to Tahoe only
#   1 = Skywalk swap only   2 = 1 + IO80211FamilyLegacy      3 = 2 + AirportItlwm
# Backs up config.plist next to it before every change.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
S=${1:?stage 0, 1, 2 or 3}; case "$S" in 0|1|2|3) ;; *) echo "stage 0-3"; exit 1;; esac
H="$(cd "$(dirname "$0")" && pwd)"; . "$H/../scripts/efi-common.sh"
cp -p "$CFG" "$MP/EFI/OC/config.plist.before-wifi-stage$S-$(date +%Y%m%d-%H%M%S)"
PY=/usr/bin/python3
[ "$(sw_vers -productVersion | cut -d. -f1)" = 27 ] && PY=/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/Resources/Python.app/Contents/MacOS/Python
"$PY" -I "$H/oc-wifi.py" "$CFG" "$S"
plutil -lint "$CFG"; echo "Stage $S set. Restart macOS 27."
