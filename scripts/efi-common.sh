# findet die OpenCore-EFI der SSD mit "macOS 27" und haengt sie beschreibbar ein
VOL=$(diskutil list | awk '/APFS Volume macOS 27 *[0-9.]+ [KMGT]B/{print $NF; exit}')
[ -n "$VOL" ] || { echo "FEHLER: Volume 'macOS 27' nicht gefunden"; exit 1; }
CONT=$(diskutil info "$VOL" | awk -F': *' '/APFS Container:/{print $2}')
STORE=$(diskutil list "$CONT" | awk '/Physical Store/{print $NF; exit}')
WHOLE=$(diskutil info "$STORE" | awk -F': *' '/Part of Whole/{print $2}')
DISK=$(diskutil list "$WHOLE" | awk '$2=="EFI"{print $NF; exit}')
[ -n "$DISK" ] || { echo "FEHLER: keine EFI-Partition auf $WHOLE"; exit 1; }
echo "OpenCore-EFI: $DISK"
diskutil unmount "$DISK" >/dev/null 2>&1 || true
diskutil mount "$DISK" >/dev/null
MP=$(diskutil info "$DISK" | awk -F': *' '/Mount Point/{print $2}')
trap 'diskutil unmount "$DISK" >/dev/null 2>&1 || true' EXIT
CFG="$MP/EFI/OC/config.plist"; KX="$MP/EFI/OC/Kexts"
[ -f "$CFG" ] || { echo "FEHLER: $CFG nicht gefunden"; exit 1; }
PB=/usr/libexec/PlistBuddy
