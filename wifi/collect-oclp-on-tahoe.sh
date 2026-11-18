#!/bin/bash
# Run on macOS 26 Tahoe AFTER the OCLP "Modern Wireless" root patch was applied there.
# Copies the patched frameworks to the macOS 27 data volume. These files are not part of this repository.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
[ "$(sw_vers -productVersion | cut -d. -f1)" = 26 ] || { echo "run this on macOS 26 Tahoe"; exit 1; }
V="/Volumes/macOS 27 - Data"; [ -d "$V/Users/Shared" ] || { echo "ERROR: $V is not mounted"; exit 1; }
SRC=/System/Library/PrivateFrameworks; D="$V/Users/Shared/wifi27-oclp-fw"
[ -f "$SRC/IO80211.framework/Versions/A/IO80211Old.dylib" ] || { echo "ERROR: OCLP Modern Wireless patch not found on this system"; exit 1; }
rm -rf "$D"
copy() { # framework, files...
  local f=$1; shift; mkdir -p "$D/$f.framework/Versions/A"
  for x in "$@"; do cp -X "$SRC/$f.framework/Versions/A/$x" "$D/$f.framework/Versions/A/$x"; done
  ln -s A "$D/$f.framework/Versions/Current"; ln -s "Versions/Current/$f" "$D/$f.framework/$f"
}
copy IO80211 IO80211 IO80211Old.dylib
copy WiFiPeerToPeer WiFiPeerToPeer WiFiPeerToPeerOld.dylib LibSystemShim.dylib
echo "Copied to $D"
