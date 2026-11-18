# Rebuild checklist macOS 27 (for Claude and other AI assistants)

How to bring a **fresh macOS 27 beta install** (laid down by NullMoth's Liberator / 1401) on the ASUS ROG Strix SCAR 18
G835LXG to the reference state. Work from top to bottom, check each step before starting the next, do not skip checks.

Reference state (17 Nov 2026): macOS 27.2 beta (26B123) next to macOS 26.7.3 Tahoe in the same APFS container,
NullMoth NVRM 2.9 + a2x, OpenCore EFI from the Tahoe project.

## 0. Rules

- **The user types every password.** Prepare `sudo` commands or scripts; never type or store a password.
- **Back up `config.plist` before every EFI change** (all scripts here do it next to the file).
- Keep Tahoe bootable at all times. Every step that can break macOS 27 has a way back that runs **from Tahoe**.
- Ask before pushing to GitHub or posting anything.
- **macOS 27 boots slowly**: after the verbose text stops, the prohibitory sign stays 4–5 minutes before the desktop.
  Wait at least 10 minutes before you call a boot "hung". Power off by holding the power button.
- The unified log on 27 does **not** contain early kext output. Use `sudo dmesg` early, or the boot capture
  ([scripts/boot-capture](../scripts/boot-capture)), or read `/var/log` on the 27 data volume from Tahoe.

## 1. Where am I?

```bash
sw_vers                                         # 26.x = Tahoe, 27.x = macOS 27
diskutil list                                   # disk numbers change between boots – never reuse old ones
diskutil list | grep "macOS 27"                 # system "macOS 27" + data "macOS 27 - Data"
```

The scripts find the OpenCore EFI of the disk that holds the "macOS 27" volume themselves (`scripts/efi-common.sh`).

## 2. Order

| # | Step | Where | Check |
| --- | --- | --- | --- |
| 1 | Install macOS 27 with Liberator/1401 (delete an old 27 install first; "Prepare" over an old one leaves a stale aux KC) | Tahoe | volumes "macOS 27" + "macOS 27 - Data" exist |
| 2 | Boot fix: I2C group in OpenCore (section 3) | Tahoe | `config.plist` lint OK |
| 3 | First boot → Setup Assistant crashes → create user offline (section 4) | Tahoe | `.AppleSetupDone` exists |
| 4 | Boot 27, log in, hide Finder sidebar | 27 | desktop, Finder stable |
| 5 | Command Line Tools on 27: `xcode-select --install` | 27 | `clang --version` |
| 6 | Speakers step 1: amplifiers (section 5) | 27 | `TAS2781DirectI2C` state `auto: initialized` |
| 7 | Speakers step 2: VoodooHDA aux KC (section 6) | **Tahoe** | 5 kexts in the new aux KC, sound on 27 |
| 8 | ROG Licht / ASUS WMI (section 7) | 27 | asus-hotkeys log shows `0x0` |
| 9 | Optional: GPU `acpi-path` injector (section 8) | 27 | NVKMS backlight registered (panel still does not dim) |
| 10 | Games (WoW): `sudo tools/nvmtl-option/nvmtl-option.sh NVMTL_NAK_NO_PREDLOAD on` (Tahoe repo) | 27 | `gx.log` shows no "Compute Pipeline Create Failed" (WoW still flickers until NullMoth fixes the shader translator) |
| 11 | Wi-Fi: frameworks from Tahoe, OpenCore stage 3, TCP workaround, build and install the service ([guide](wifi-27.md)) | Tahoe, then 27 | `/var/log/airportd-wifi27.log` shows all three "running" lines; join from the menu works |
| 12 | Bluetooth: firmware loader on, `IntelBTPatcher` off ([guide](bluetooth-27.md)) | Tahoe or 27 | `bluetoothd` `runs = 1`, device can be paired |

## 3. Boot fix (WindowServer hang)

Without it WindowServer waits forever in `IOKitWaitQuiet` because I2C0/I2C4 stay `busy` ([findings §1](findings.md)).
Pick **one**:

```bash
# A) no touchpad driver on 27 at all (simplest, known good)
sudo scripts/oc-maxkernel.sh 26.99.99 LegionI2CArrowLake.kext
# B) whole VoodooI2C group on 27 (boots too, touchpad still does not work)
sudo scripts/oc-maxkernel.sh 27.99.99 VoodooI2C.kext VoodooI2C.kext/Contents/PlugIns/VoodooI2CServices.kext \
  VoodooI2C.kext/Contents/PlugIns/VoodooGPIO.kext VoodooI2C.kext/Contents/PlugIns/VoodooInput.kext VoodooI2CHID.kext LegionI2CArrowLake.kext
```
Check after boot: `ioreg -w0 -p IOService | grep -E "busy [1-9]"` prints nothing.

## 4. User without Setup Assistant

Setup Assistant crashes (SIGFPE in VFX ← AvatarKit `AVTStickerGenerator`) and the machine restarts. From Tahoe:
```bash
sudo scripts/create-user-offline.sh     # asks short name, full name; dscl asks the password itself
```
It creates a local admin on "macOS 27 - Data" via `dscl -f …/dslocal/nodes/Default localonly` (node `/Local/Target`),
sets per-user "DidSee…" keys and `.AppleSetupDone`. Undo: `scripts/create-user-offline-undo.sh`.

Then on 27: **Finder → View → Hide Sidebar** (Ctrl+Cmd+S), otherwise Finder crashes whenever a disk or iPhone appears.

## 5. Speakers step 1 – amplifiers (on 27)

1. Get the Tahoe repo source, apply [`patches/TAS2781DirectI2C-0.5.5-macos27.patch`](../patches) and set `VERSION=0.5.5` in `build.sh`.
2. TI firmware into `drivers/TAS2781DirectI2C/firmware/` (linux-firmware `ti/audio/tas2781/`, check SHA-256 from its README).
3. Build **on the laptop** (reads `CALI_DATA`). On 27 `python3` does not start through its stub; use
   `PY=/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/Resources/Python.app/Contents/MacOS/Python`
   and replace `python3` in `build.sh` with `"$PY"` (see [`patches/build-27.diff`](../patches/build-27.diff)).
4. Install both via OpenCore (Darwin 27 only):
   ```bash
   sudo scripts/oc-kext.sh add kexts/TASAcpiPathInjector.kext
   sudo scripts/oc-kext.sh add path/to/build/TAS2781DirectI2C.kext
   ```
5. Restart, check:
   ```bash
   ioreg -w0 -l -r -n "I2C0@15" -d1 | grep TAS2781DirectI2C-start   # "started, comp 44570140 … now: con 75 …"
   ioreg -w0 -l -r -c TAS2781DirectI2C | grep -o '"State"="[^"]*"'   # "auto: initialized"
   ```

## 6. Speakers step 2 – VoodooHDA in the 27 aux KC (on Tahoe)

`kmutil` on 27 reads KC UUIDs wrong (a2x) and cannot build collections. On Tahoe:
```bash
sudo VOODOOHDA=/Library/Extensions/VoodooHDA.kext scripts/aux-kc-voodoohda-on-tahoe.sh
```
It collects NMXAudio, NVAccel, NVRMAGDC, NVRMFB from the 27 data volume + VoodooHDA, runs
`kmutil create -n aux -x -b … -B <27 BootKC> -S <27 SystemKC>` (no `--volume-root`), checks `_BootKCID` against the old aux KC,
backs it up as `AuxiliaryKernelExtensions.kc.before-voodoohda` and replaces the content.
Way back: `sudo scripts/aux-kc-revert-on-tahoe.sh`. **After every NullMoth update for 27, run it again.**

Check on 27: `system_profiler SPAudioDataType` shows "Realtek ALC285: Speaker"; play a sound.

## 7. ROG Licht / ASUS keys (on 27)

1. Build `ASUSG835WMI` with the Tahoe repo (or copy from Tahoe `/Library/Extensions`), then
   `sudo scripts/oc-kext.sh add path/to/ASUSG835WMI.kext` and restart. Check: `ioreg -p IOService | grep -A1 ATKD` shows `ASUSG835WMI`.
2. Install ROG Licht and asus-hotkeys as on Tahoe (`tools/asus-hotkeys/install.sh` of the Tahoe repo; fix paths if you copy LaunchAgents).
3. System Settings → Privacy & Security → **Input Monitoring** → allow `asus-hotkeys`, then
   `launchctl kickstart -k gui/$(id -u)/de.codex.asushotkeys`. Log `~/Library/Logs/asus-hotkeys.log` must show `IOHIDManagerOpen 0x0`.

## 8. Optional / experimental

| Kext | Effect | Status |
| --- | --- | --- |
| `GPUAcpiPathInjector` | gives the GPU its `acpi-path` → NVRM runs `NBCI _DSM`, NVKMS registers the backlight like on Tahoe | slider "applied", panel unchanged |
| `I2CAcpiPathInjector` | gives I2C0/I2C4 their `acpi-path` → VoodooI2C attaches | **hard freeze** of macOS 27 – do not use |

## 9. Do not

- Do not overwrite `Preboot/Cryptexes/OS` with the 27 cryptex: it is Tahoe's live x86 cryptex and a2x relies on it.
- Do not build the 27 aux KC on 27 itself.
- Do not use `--volume-root` with absolute `-B/-S` paths in `kmutil create`.
