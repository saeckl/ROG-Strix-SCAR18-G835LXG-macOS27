#!/bin/bash
# Entfernt das per Skript angelegte Konto wieder und laesst den Setup-Assistenten erneut laufen.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Bitte mit sudo starten."; exit 1; }
DATA="/Volumes/macOS 27 - Data"; DS="$DATA/private/var/db/dslocal/nodes/Default"; N=/Local/Target
M="$DATA/private/var/db/.m27-user-created-by-script"
[ -f "$M" ] || { echo "FEHLER: kein per Skript angelegtes Konto vermerkt"; exit 1; }
U=$(cat "$M"); dscl() { /usr/bin/dscl -f "$DS" localonly "$@"; }
GUID=$(dscl -read "$N/Users/$U" GeneratedUID | awk '{print $2}')
dscl -delete "$N/Groups/admin" GroupMembership "$U" || true
[ -n "$GUID" ] && dscl -delete "$N/Groups/admin" GroupMembers "$GUID" || true
dscl -delete "$N/Users/$U"
rm -rf "$DATA/Users/$U"; rm -f "$DATA/private/var/db/.AppleSetupDone" "$M"
echo "Konto $U entfernt, Setup-Assistent laeuft beim naechsten Start wieder."
