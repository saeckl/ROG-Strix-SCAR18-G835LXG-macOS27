#!/bin/bash
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Bitte mit sudo starten."; exit 1; }
DATA="/Volumes/macOS 27 - Data"; AUX="$DATA/Library/KernelCollections/AuxiliaryKernelExtensions.kc"; BK="$AUX.before-voodoohda"
[ -f "$BK" ] || { echo "FEHLER: keine Sicherung $BK"; exit 1; }
cat "$BK" > "$AUX"; chmod 744 "$AUX"; rm -rf "$DATA/Library/Extensions/VoodooHDA.kext"
kmutil inspect -a x86_64 -A "$AUX" | awk -F '\t' 'NF>2{print "  "$1}'; echo "Alte Aux-KC wiederhergestellt."
