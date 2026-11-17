#!/bin/bash
# Installiert den WindowServer-Mitschnitt NUR auf "macOS 27 - Data". Tahoe wird nicht veraendert.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Bitte mit sudo starten."; exit 1; }
D="/Volumes/macOS 27 - Data"; H="$(cd "$(dirname "$0")" && pwd)"
[ -d "$D/Library/LaunchDaemons" ] || { echo "FEHLER: $D nicht gefunden."; exit 1; }
mkdir -p "$D/Library/WSDebug"
install -o root -g wheel -m 755 "$H/ws-debug.sh" "$D/Library/WSDebug/ws-debug.sh"
install -o root -g wheel -m 644 "$H/local.wsdebug.plist" "$D/Library/LaunchDaemons/local.wsdebug.plist"
rm -rf "$D/private/var/log/ws-debug"
ls -la "$D/Library/WSDebug" "$D/Library/LaunchDaemons/local.wsdebug.plist"
echo "Installiert. Jetzt macOS 27 starten und mindestens 7 Minuten laufen lassen."
