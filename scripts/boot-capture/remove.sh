#!/bin/bash
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Bitte mit sudo starten."; exit 1; }
D="/Volumes/macOS 27 - Data"
rm -f "$D/Library/LaunchDaemons/local.wsdebug.plist"; rm -rf "$D/Library/WSDebug"
echo "Entfernt."
