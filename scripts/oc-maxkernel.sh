#!/bin/bash
# Set MaxKernel of existing OpenCore Kernel>Add entries (by BundlePath).
#   sudo ./oc-maxkernel.sh 26.99.99 LegionI2CArrowLake.kext
#   sudo ./oc-maxkernel.sh 27.99.99 VoodooI2C.kext VoodooI2CHID.kext ...
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
H="$(cd "$(dirname "$0")" && pwd)"; . "$H/efi-common.sh"
v=${1:?version}; shift
cp -p "$CFG" "$MP/EFI/OC/config.plist.before-maxkernel-$(date +%Y%m%d-%H%M%S)"
for b in "$@"; do i=0; found=0
  while bp=$($PB -c "Print :Kernel:Add:$i:BundlePath" "$CFG" 2>/dev/null); do
    if [ "$bp" = "$b" ]; then $PB -c "Set :Kernel:Add:$i:MaxKernel $v" "$CFG"; echo "$b -> MaxKernel $v"; found=1; fi; i=$((i+1)); done
  [ $found = 1 ] || echo "WARNING: $b not in config"
done
plutil -lint "$CFG"
