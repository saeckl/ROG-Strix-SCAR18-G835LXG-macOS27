# Bluetooth on macOS 27 (Intel `8087:0036`)

Tested on macOS 27.2 beta (26B123) on one G835LXG, with `IntelBluetoothFirmware` 2.5.0 and `BlueToolFixup` 2.7.7 from the Tahoe EFI.

## Status

| Function | Status |
| --- | --- |
| Controller on, `bluetoothd` stable | works |
| BLE scan | works |
| Pairing and connecting a device | works |
| AirDrop | **does not work**: finds nobody and is not found. see [airdrop-27.md](airdrop-27.md) |
| Handoff, Universal Clipboard | not tested (need an Apple Account) |

## Setup

Both kexts are already in the Tahoe EFI, limited to Darwin 26. Only the firmware loader is needed on macOS 27:

```bash
sudo scripts/oc-maxkernel.sh 27.99.99 IntelBluetoothFirmware.kext
sudo scripts/oc-maxkernel.sh 26.99.99 IntelBTPatcher.kext
```

Restart. `BlueToolFixup` must stay enabled. Both commands back up `config.plist` and also work from Tahoe.

Check:

```bash
kmutil showloaded --list-only | grep -E "IntelBluetooth|IntelBTPatcher|BlueToolFixup"
launchctl print system/com.apple.bluetoothd | grep -E "state =|runs =|last exit code"
system_profiler SPBluetoothDataType | head -12
```

`IntelBluetoothFirmware` and `BlueToolFixup` should be listed, `IntelBTPatcher` should not. `runs` should stay at 1.

Way back: `sudo scripts/oc-maxkernel.sh 26.99.99 IntelBluetoothFirmware.kext`, then restart.

## Why IntelBTPatcher stays off

With `IntelBTPatcher` loaded, `bluetoothd` restarted every few seconds (more than 200 runs, exit 1). Its log shows:

```text
Command Complete, orphan event, opcode: 00002005, status OI_OK
Bluetooth error - restarting { build=release, reason=635, context="OI_DHCI_CMD_ID_LE_SET_RANDOM_ADDRESS_OPCODE" }
```

The patcher sends its own hardcoded *LE Set Random Address* command (`0x2005`) before the first LE scan. `bluetoothd` on macOS 27
receives a completion for a command it did not send and restarts. Without the patcher the restart loop is gone, and on this
machine BLE scanning and pairing work.
