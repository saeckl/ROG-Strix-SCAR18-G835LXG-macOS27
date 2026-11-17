#!/bin/bash
# UNTER TAHOE AUSFUEHREN: baut die Aux-KC von macOS 27 neu (NullMoth-Kexts + VoodooHDA),
# gegen die Boot-/System-KC auf dem 27-Volume, sichert die alte und setzt die neue ein.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
[ "$(id -u)" = 0 ] || { echo "Bitte mit sudo starten."; exit 1; }
[ "$(sw_vers -productVersion | cut -d. -f1)" = 26 ] || { echo "Bitte unter Tahoe (macOS 26) ausfuehren."; exit 1; }
H="$(cd "$(dirname "$0")" && pwd)"
SYS="/Volumes/macOS 27"; DATA="/Volumes/macOS 27 - Data"
KCS="$SYS/System/Library/KernelCollections"; AUX="$DATA/Library/KernelCollections/AuxiliaryKernelExtensions.kc"
for f in "$KCS/BootKernelExtensions.kc" "$KCS/SystemKernelExtensions.kc" "$AUX"; do [ -f "$f" ] || { echo "FEHLER: fehlt $f"; exit 1; }; done
ST=/Users/Shared/kaux27/Library/Extensions; rm -rf /Users/Shared/kaux27; mkdir -p "$ST"
echo "== Kexts sammeln"
for k in NMXAudio NVAccel NVRMAGDC NVRMFB; do ditto "$DATA/Library/Extensions/$k.kext" "$ST/$k.kext"; done
ditto "${VOODOOHDA:?set VOODOOHDA=/path/to/VoodooHDA.kext}" "$ST/VoodooHDA.kext"
chown -R root:wheel /Users/Shared/kaux27; chmod -R go-w /Users/Shared/kaux27
echo "== alte Aux-KC"; kmutil inspect -a x86_64 -A "$AUX" | awk -F '\t' 'NF>2{print "  "$1}'
NEW=/Users/Shared/kaux27/New.kc
echo "== baue neue Aux-KC"
# ohne --volume-root (sonst setzt kmutil die absoluten -B/-S-Pfade doppelt zusammen -> "No such file or directory"),
# mit -x + -b, damit nur diese 5 Kexts hineinkommen und nichts aus Tahoes /Library/Extensions (z.B. AppleMobileDevice)
kmutil create -n aux --allow-missing-kdk -x -B "$KCS/BootKernelExtensions.kc" -S "$KCS/SystemKernelExtensions.kc" \
  --repository "$ST" -b com.nullmoth.NVAccel -b com.nullmoth.NMXAudio -b com.nullmoth.NVRMAGDC -b com.nullmoth.NVRMFB \
  -b org.voodoo.driver.VoodooHDA -A "$NEW" -z > /Users/Shared/kaux27/kmutil.log 2>&1 || { tail -30 /Users/Shared/kaux27/kmutil.log; echo "FEHLER: nichts geaendert"; exit 1; }
# muss gegen dieselbe Boot-KC gelinkt sein wie die alte Aux-KC (auxkcload prueft das)
kcid() { python3 -I -c 'import sys,plistlib; b=open(sys.argv[1],"rb").read(); j=b.find(b"<?xml"); e=b.find(b"</plist>",j); print(plistlib.loads(b[j:e+8])["_BootKCID"].hex())' "$1"; }
[ "$(kcid "$NEW")" = "$(kcid "$AUX")" ] || { echo "FEHLER: neue Aux-KC ist gegen eine andere Boot-KC gelinkt - nichts geaendert"; exit 1; }
echo "Boot-KC-Verknuepfung passt ($(kcid "$NEW"))"
echo "== neue Aux-KC"; kmutil inspect -a x86_64 -A "$NEW" | awk -F '\t' 'NF>2{print "  "$1}' | tee /Users/Shared/kaux27/after.txt
for k in com.nullmoth.NVAccel com.nullmoth.NMXAudio com.nullmoth.NVRMAGDC com.nullmoth.NVRMFB org.voodoo.driver.VoodooHDA; do
  grep -q "$k" /Users/Shared/kaux27/after.txt || { echo "FEHLER: $k fehlt in der neuen KC - nichts geaendert"; exit 1; }; done
BK="$AUX.before-voodoohda"
[ -f "$BK" ] || cp -p "$AUX" "$BK"; echo "Sicherung: $BK"
cat "$NEW" > "$AUX"                    # Inhalt ersetzen, Rechte/Flags der Datei bleiben
chmod 744 "$AUX"; ls -lO "$AUX"
ditto "${VOODOOHDA:?set VOODOOHDA=/path/to/VoodooHDA.kext}" "$DATA/Library/Extensions/VoodooHDA.kext"; chown -R root:wheel "$DATA/Library/Extensions/VoodooHDA.kext"
echo "Fertig. macOS 27 starten. Rueckgaengig (unter Tahoe): sudo bash \"$H/revert-on-tahoe.sh\""
