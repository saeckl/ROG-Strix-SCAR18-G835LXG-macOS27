#!/bin/bash
# Legt auf "macOS 27 - Data" ein lokales Admin-Konto an und markiert den Setup-Assistenten als erledigt.
# Tahoe wird nicht veraendert. Das Passwort fragt dscl selbst ab (Eingabe wird nicht angezeigt).
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Bitte mit sudo starten."; exit 1; }
DATA="/Volumes/macOS 27 - Data"; SYS="/Volumes/macOS 27"
DS="$DATA/private/var/db/dslocal/nodes/Default"; N=/Local/Target
TPL="$SYS/Library/User Template/Non_localized"
[ -d "$DS/users" ] || { echo "FEHLER: Benutzerdatenbank von macOS 27 nicht gefunden ($DS)"; exit 1; }
dscl() { /usr/bin/dscl -f "$DS" localonly "$@"; }

read -r -p "Kurzname fuer das neue Konto (klein, ohne Leerzeichen, z.B. john): " U
[[ "$U" =~ ^[a-z_][a-z0-9_]{0,30}$ ]] || { echo "FEHLER: ungueltiger Kurzname"; exit 1; }
read -r -p "Voller Name: " RN
[ -n "$RN" ] || RN="$U"
dscl -read "$N/Users/$U" >/dev/null 2>&1 && { echo "FEHLER: Konto $U gibt es schon"; exit 1; }

UIDN=501
while dscl -search "$N/Users" UniqueID "$UIDN" 2>/dev/null | grep -q .; do UIDN=$((UIDN+1)); done
GUID=$(uuidgen)
echo "== Lege Konto $U (UID $UIDN) an"
dscl -create "$N/Users/$U"
dscl -create "$N/Users/$U" RealName "$RN"
dscl -create "$N/Users/$U" UniqueID "$UIDN"
dscl -create "$N/Users/$U" PrimaryGroupID 20
dscl -create "$N/Users/$U" UserShell /bin/zsh
dscl -create "$N/Users/$U" NFSHomeDirectory "/Users/$U"
dscl -create "$N/Users/$U" GeneratedUID "$GUID"
echo "== Passwort fuer $U festlegen (zweimal eingeben, wird nicht angezeigt):"
dscl -passwd "$N/Users/$U"
dscl -append "$N/Groups/admin" GroupMembership "$U"
dscl -append "$N/Groups/admin" GroupMembers "$GUID"

echo "== Benutzerordner anlegen"
H="$DATA/Users/$U"
if [ ! -d "$H" ]; then
  if [ -d "$TPL" ]; then /usr/bin/ditto "$TPL" "$H"; else mkdir -p "$H"; fi
fi
P="$H/Library/Preferences"; mkdir -p "$P"
# Assistent beim ersten Anmelden moeglichst ueberspringen
SA="$P/com.apple.SetupAssistant.plist"
for k in DidSeeCloudSetup DidSeeSiriSetup DidSeePrivacy DidSeeScreenTime DidSeeAppearanceSetup DidSeeTouchIDSetup \
         DidSeeActivationLock DidSeeAccessibility DidSeeTrueTone DidSeeApplePaySetup DidSeeAvatarSetup DidSeeSyncSetup \
         DidSeeSyncSetup2 DidSeeiCloudLoginForStorageServices DidSeeIntelligence DidSeeTermsOfAddress SkipFirstLoginOptimization; do
  /usr/bin/defaults write "$SA" "$k" -bool true
done
/usr/bin/defaults write "$SA" LastSeenCloudProductVersion "27.2"
/usr/bin/defaults write "$SA" LastSeenBuddyBuildVersion "26B123"
chown -R "$UIDN":20 "$H"

echo "== Setup-Assistent als erledigt markieren"
touch "$DATA/private/var/db/.AppleSetupDone"
echo "$U" > "$DATA/private/var/db/.m27-user-created-by-script"

echo "== Kontrolle"
dscl -read "$N/Users/$U" RealName UniqueID PrimaryGroupID NFSHomeDirectory UserShell
dscl -read "$N/Users/$U" AuthenticationAuthority 2>/dev/null | grep -q ShadowHash && echo "Passwort: gesetzt" || echo "WARNUNG: kein Passwort-Eintrag gefunden"
dscl -read "$N/Groups/admin" GroupMembership
ls -la "$DATA/private/var/db/.AppleSetupDone"
echo "Fertig. Rueckgaengig: sudo bash ./create-user-offline-undo.sh"
