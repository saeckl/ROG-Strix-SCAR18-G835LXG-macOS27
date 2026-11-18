# Wi-Fi on macOS 27 (Intel BE200, AirportItlwm)

Tested on macOS 27.2 beta (26B123) on one G835LXG with an Intel BE200 (`8086:272b`), AirportItlwm 2.0.0 and NullMoth a2x.
The system volume is not changed. Everything added on macOS 27 can be removed with [`wifi/remove.sh`](../wifi/remove.sh).

## Status

| Function | Status |
| --- | --- |
| Scan, network list, join by click (WPA2/WPA3 transition network) | works |
| Internet over Wi-Fi, survives a restart | works |
| Wi-Fi menu and on/off switch | works, a few minutes after login (see below) |
| AirPlay | works |
| **Automatic join** after boot or after Wi-Fi off/on | **does not work**, one click on the saved network is needed; the password stays saved |
| 802.1X / enterprise Wi-Fi | not available (the EAPOL service is stubbed out) |
| AirDrop | does not work, finds nobody and is not found ([Bluetooth notes](bluetooth-27.md)) |
| Handoff | not tested |

## What is needed and why

| Part | Why |
| --- | --- |
| Block Apple's `IOSkywalkFamily`, inject the older one | AirportItlwm and `IO80211FamilyLegacy` need the older Skywalk interface (same as on Tahoe) |
| Also block `AppleEthernetRL` | it depends on Apple's Skywalk and hangs on the RTL8125 (`stuck RP07`, then "Still waiting for root device"). `RTL812xLucy` keeps Ethernet working |
| `IO80211FamilyLegacy` + `AirportItlwm` for Darwin 27 | the Wi-Fi driver itself |
| OCLP `IO80211` + `WiFiPeerToPeer` frameworks for `airportd` | with macOS 27's own IO80211, `airportd` sees `en3` but every scan returns 0 networks. They are loaded with `DYLD_FRAMEWORK_PATH`, not installed into the system |
| Log stubs in the shim | `IO8Log2` and friends are variadic. ARM64 passes those arguments on the stack, x86_64 in registers, so the a2x bridge crashes (`airportd` exit 139) |
| `apple80211_*toStr` stubs | plain functions on macOS 27, data symbols in the OCLP shim. Calling them gives SIGBUS |
| EAPOL stubs | `configd` runs as x86_64, but `EAPOLController.bundle` exists only as arm64e and never loads. The Mach service is registered and never answers, so every `EAPOLControl*` call blocks forever. In `airportd` that stops scans and joins (120 s timeout), in `WiFiAgent` and `ControlCenter` it freezes the menu and the switch |
| Boot service `local.wifi27-airportd` | starts these processes with the right environment through `launchctl debug` at every boot and restarts them if needed |
| Driver watchdog in the service | the driver sometimes stops scanning. Joins then time out after about 21 s. Bringing the interface down and up fixes it, so the service does that after 45 s without a scan while disconnected |
| `net.inet.tcp.prr=0` | avoids a kernel panic (division by zero in `tcp_prr_update`) seen on macOS 27 |

## To do, in this order

Requirements: Wi-Fi already works on Tahoe with AirportItlwm, the OCLP **Modern Wireless** root patch is applied there, the
EFI contains `IOSkywalkFamily.kext`, `IO80211FamilyLegacy.kext`, `AirportItlwm.kext` and the two `Kernel > Block` entries
(`com.apple.iokit.IOSkywalkFamily`, `com.apple.driver.AppleEthernetRL`). macOS 27 boots and has the Command Line Tools.
None of these binaries are in this repository.

1. **On Tahoe**, copy the patched frameworks to the macOS 27 data volume:
   ```bash
   sudo wifi/collect-oclp-on-tahoe.sh
   ```
2. **On Tahoe or macOS 27**, enable the kexts for Darwin 27 (backs up `config.plist`):
   ```bash
   sudo wifi/oc-wifi.sh 3
   ```
   If the machine no longer boots, use stages 1 and 2 to find the step that fails. `sudo wifi/oc-wifi.sh 0` goes back.
3. Install the TCP workaround:
   ```bash
   sudo wifi/tcp-prr/install.sh
   ```
4. Restart into macOS 27. Until step 5 is done, `airportd` crash-loops. That is expected.
5. **On macOS 27**, build and install:
   ```bash
   wifi/build.sh
   wifi/install.sh --check
   sudo wifi/install.sh
   ```
6. Open the Wi-Fi menu, choose the network from the list and enter the password. Do not add it through "Other…".

After each restart the service needs a moment. On the test machine `WiFiAgent` and `ControlCenter` were ready about seven
minutes after boot, so the menu can be empty or wrong until then. A first `ERROR` line in the log is retried automatically.

## Checks

```bash
cat /var/log/airportd-wifi27.log
launchctl print system/local.wifi27-airportd | grep -E "state|pid ="
networksetup -listallhardwareports | grep -A1 Wi-Fi
grep -a -c a2x-stop /var/log/airportd-wifi27.err    # should be 0
```

The log should contain `airportd running with OCLP files`, `com.apple.wifi.WiFiAgent running with EAPOL shim` and
`com.apple.controlcenter running with EAPOL shim`.

## Way back

```bash
sudo wifi/remove.sh
sudo wifi/oc-wifi.sh 0
sudo wifi/tcp-prr/remove.sh    # optional
```

`remove.sh` and `oc-wifi.sh` also work from Tahoe.

## Open problems

**Automatic join.** `airportd` knows the saved network and scans, but auto-join ends with `Scan Results (0)`,
`candidateBSSCount=0` and "Known network is found nearby but not joined". What was checked:

- Normal scans return networks with every tested combination of channel list, dwell time, scan type and scan flags.
- Removing the privacy filter from `airportd`'s own scan results (`-[CWFXPCConnection __filterScanResultsForPrivacy:]`) changed nothing.
- Saving the network again from the list instead of "Other…" changed nothing. It is still treated as a hidden network.
- Not proven: the network is saved as WPA3 Personal (transition mode), while the driver joins it with WPA2-PSK.

**`rapportd` and `sharingd`** also wait on the EAPOL service in a background thread. With the EAPOL shim they crashed
(exit 139), so the service leaves them alone. Whether this affects Continuity features is not known yet.

**AirDrop.** `awdl0` is up and `sharingd` starts its listener, but no peers appear. `wifip2pd` is not replaced. Limited AWDL support in AirportItlwm is the likely cause, but this is not proven.

The cleanest fix for the EAPOL part would be an x86_64 `EAPOLController` plugin for `configd`, which belongs into the a2x
system files. It was not tried because it means changing the system volume.
