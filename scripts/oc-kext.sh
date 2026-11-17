#!/bin/bash
# Add or remove a kext in the OpenCore config of the macOS 27 disk, limited to Darwin 27 (MinKernel 27.0.0, MaxKernel 27.99.99).
#   sudo ./oc-kext.sh add    path/to/X.kext      # code kext: ExecutablePath is taken from Info.plist; codeless: empty
#   sudo ./oc-kext.sh remove X.kext
# Backs up config.plist next to it before every change.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
H="$(cd "$(dirname "$0")" && pwd)"; . "$H/efi-common.sh"
cmd=${1:?add|remove}; arg=${2:?kext}; name=$(basename "$arg")
cp -p "$CFG" "$MP/EFI/OC/config.plist.before-$name-$cmd-$(date +%Y%m%d-%H%M%S)"
idx() { local i=0 bp; while bp=$($PB -c "Print :Kernel:Add:$i:BundlePath" "$CFG" 2>/dev/null); do [ "$bp" = "$1" ] && { echo $i; return; }; i=$((i+1)); done; }
case "$cmd" in
add)
  exe=$($PB -c "Print :CFBundleExecutable" "$arg/Contents/Info.plist" 2>/dev/null || true); ep=""; [ -n "$exe" ] && ep="Contents/MacOS/$exe"
  rm -rf "$KX/$name"; cp -R "$arg" "$KX/"
  if [ -n "$(idx "$name")" ]; then echo "entry $name exists, kext replaced"; else
    N=$($PB -c "Print :Kernel:Add" "$CFG" | grep -c "BundlePath")
    $PB -c "Add :Kernel:Add:$N dict" -c "Add :Kernel:Add:$N:Arch string Any" -c "Add :Kernel:Add:$N:BundlePath string $name" \
        -c "Add :Kernel:Add:$N:Comment string macOS 27" -c "Add :Kernel:Add:$N:Enabled bool true" -c "Add :Kernel:Add:$N:ExecutablePath string $ep" \
        -c "Add :Kernel:Add:$N:MaxKernel string 27.99.99" -c "Add :Kernel:Add:$N:MinKernel string 27.0.0" \
        -c "Add :Kernel:Add:$N:PlistPath string Contents/Info.plist" "$CFG"; echo "entry $N: $name"; fi ;;
remove)
  i=$(idx "$name"); [ -n "$i" ] && { $PB -c "Delete :Kernel:Add:$i" "$CFG"; echo "entry $i removed"; }; rm -rf "$KX/$name" ;;
*) echo "add|remove"; exit 1;;
esac
plutil -lint "$CFG"
