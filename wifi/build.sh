#!/bin/bash
# Builds the two shims into wifi/build. Run on macOS 27 with the Command Line Tools (xcode-select --install).
set -euo pipefail
H="$(cd "$(dirname "$0")" && pwd)"; B="$H/build"; mkdir -p "$B"; cd "$H/src"
F="-arch x86_64 -mmacosx-version-min=26.0 -O2 -dynamiclib"
clang $F -install_name /Library/WiFi27/libio80211logshim.dylib airportd-shim.c IO80211.tbd EAP8021X.tbd -o "$B/libio80211logshim.dylib"
clang $F -install_name /Library/WiFi27/libeapolshim.dylib eapol-shim.c EAP8021X.tbd -o "$B/libeapolshim.dylib"
codesign -f -s - "$B/libio80211logshim.dylib" "$B/libeapolshim.dylib"
echo "Built: $B"
