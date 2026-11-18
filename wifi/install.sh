#!/bin/bash
# Installs the Wi-Fi service on macOS 27. Nothing on the system volume is changed.
#   ./build.sh                      (once, without sudo)
#   sudo ./install.sh
#   ./install.sh --check            only checks that all files are there
set -euo pipefail
H="$(cd "$(dirname "$0")" && pwd)"; R=/Library/WiFi27; P=/Library/LaunchDaemons/local.wifi27-airportd.plist
FW="${OCLP_FW:-/Users/Shared/wifi27-oclp-fw}"; LOG=/var/log/airportd-wifi27.log
[ "$(sw_vers -productVersion | cut -d. -f1)" = 27 ] || { echo "run this on macOS 27"; exit 1; }
for f in "$FW/IO80211.framework/Versions/A/IO80211Old.dylib" "$FW/WiFiPeerToPeer.framework/Versions/A/WiFiPeerToPeerOld.dylib" \
         "$H/build/libio80211logshim.dylib" "$H/build/libeapolshim.dylib" "$H/wifi27-airportd.sh" "$H/local.wifi27-airportd.plist"; do
  [ -e "$f" ] || { echo "ERROR: missing $f (see docs/wifi-27.md)"; exit 1; }
done
[ "${1:-}" = --check ] && { echo "All files found."; exit 0; }
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
launchctl bootout system/local.wifi27-airportd 2>/dev/null || true
pkill -f "launchctl debug system/com.apple.airportd" 2>/dev/null || true
mkdir -p $R; rm -rf $R/oclp-fw; cp -RXP "$FW" $R/oclp-fw
install -m 755 "$H/build/libio80211logshim.dylib" "$H/build/libeapolshim.dylib" "$H/wifi27-airportd.sh" $R/
chown -R root:wheel $R; chmod -R go-w $R
install -o root -g wheel -m 644 "$H/local.wifi27-airportd.plist" $P
rm -f $LOG
launchctl kill SIGKILL system/com.apple.airportd 2>/dev/null || true
launchctl bootstrap system $P
echo "Service loaded, waiting about 90 seconds ..."
sleep 90
chmod 644 $LOG 2>/dev/null || true; tail -8 $LOG 2>/dev/null || true
if grep -q "com.apple.controlcenter running with EAPOL shim" $LOG 2>/dev/null; then echo OK; else echo "Not finished yet, check $LOG (a first ERROR line is retried automatically)"; fi
