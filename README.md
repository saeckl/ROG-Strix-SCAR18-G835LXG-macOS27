# macOS 27 (beta) on the ASUS ROG Strix SCAR 18 (G835LXG)

Notes, small kexts, a driver patch and scripts for running the **macOS 27.2 beta** (build 26B123) on the ASUS ROG
Strix SCAR 18 **G835LXG** (Intel Core Ultra 9 290HX Plus, RTX 5090 Laptop GPU) next to a working macOS 26 Tahoe.

> Deutsche Kurzfassung: [README.de.md](README.de.md)

This builds on the Tahoe project **[ROG-Strix-SCAR18-G835LXG-macOS](https://github.com/saeckl/ROG-Strix-SCAR18-G835LXG-macOS)**
(EFI, TAS2781 speaker driver, ASUS WMI, ROG Licht) and on the **[NullMoth](https://github.com/nullmoth/nvidia-macos-driver)**
macOS 27 bring-up (x86 kernel with an ARM64E userland through NullMoth's **a2x** runtime, NVIDIA driver in an auxiliary kernel
collection). Everything was tested on exactly one laptop. It is a beta on unsupported hardware: keep Tahoe as your daily system.

## Tested system

| | |
| --- | --- |
| Laptop | ASUS ROG Strix SCAR 18 G835LXG |
| CPU | Intel Core Ultra 9 290HX Plus (Arrow Lake-HX) |
| GPU | NVIDIA RTX 5090 Laptop (`10de:2c58`), MUX on dGPU |
| macOS | 27.2 beta (26B123), next to macOS 26.7.3 Tahoe in the same APFS container |
| Driver stack | NullMoth NVRM 2.9 (NVAccel, NVRMFB, NVRMAGDC, NMXAudio in the aux KC), a2x |
| OpenCore | the EFI of the Tahoe project, plus the changes below |

## Status

| Function | Status | How |
| --- | --- | --- |
| Boot to desktop | **works** – takes 4–5 min after the kernel text stops (prohibitory sign meanwhile) | `LegionI2CArrowLake` MaxKernel 26.99.99 **or** the whole VoodooI2C group on 27.99.99 ([why](docs/findings.md#1-windowserver-waits-forever-in-iokitwaitquiet)) |
| First setup | Setup Assistant crashes (SIGFPE in VFX/AvatarKit, Memoji render) → create the user offline | [create-user-offline.sh](scripts/create-user-offline.sh) |
| RTX 5090, internal panel + HDMI, Metal 4 | works | NullMoth |
| Internal speakers, headphones, microphone | **works** | patched [TAS2781DirectI2C 0.5.5](patches) + `TASAcpiPathInjector` + VoodooHDA in the 27 aux KC ([details](docs/audio-27.md)) |
| Keyboard lighting, Aura, ROG Licht, Fn keys | **works** | `ASUSG835WMI` via OpenCore (MinKernel 27) + ROG Licht / asus-hotkeys; allow Input Monitoring, then restart the agent |
| Touchpad | **does not work** – with the missing `acpi-path` injected VoodooI2C attaches, then macOS 27 freezes hard | [findings](docs/findings.md#3-touchpad-voodooi2c-needs-acpi-path-then-freezes) |
| Display brightness | **does not work** – NVKMS backlight registers like on Tahoe, "applied" without error, panel does not change | [findings](docs/findings.md#4-display-brightness) |
| Finder | crashes when a device appears (second SSD, iPhone USB hotspot) while the sidebar is visible → **hide the sidebar** (Ctrl+Cmd+S) | a2x bug, [findings](docs/findings.md#5-finder-crash-when-a-device-appears) |
| Preview (image viewer) | crashes ~20 s after opening an image (`NSMapInsert … notAKeyMarker` from translated code) | a2x bug, [findings](docs/findings.md#7-preview-crash) |
| Dock | app context menu opens at the far left; magnification enabled but without effect | observation, no log entries |
| World of Warcraft | **flickers** – Metal device lost/recreated in a loop; `NVMTL_NAK_NO_PREDLOAD=1` fixes the compute pipelines, then two pixel shaders fail with "Shader entrypoint '_main' not found" (same NullMoth 2.9/3.0 issue as on Tahoe) | [findings](docs/findings.md#8-world-of-warcraft-flickers) |
| Wi-Fi (Intel BE200) | **works**: scan, join, internet, menu, on/off switch, AirPlay. **Automatic join does not work yet**, one click after boot or Wi-Fi off/on | AirportItlwm + OCLP frameworks + shims + boot service ([guide](docs/wifi-27.md)) |
| Ethernet, USB tethering | work | `RTL812xLucy`, iPhone USB |
| Bluetooth (Intel `8087:0036`) | **works**: BLE scan, pairing, connecting | `IntelBluetoothFirmware` + `BlueToolFixup`, `IntelBTPatcher` must stay off ([guide](docs/bluetooth-27.md)) |
| AirDrop | **does not work**: finds nobody and is not found | `sharingd` hangs on the EAPOL service and crashes under a2x with the workaround ([details](docs/airdrop-27.md)) |
| Handoff | not tested | – |
| Sleep | not tested (does not work on Tahoe either) | – |

## Repository layout

| Path | Content |
| --- | --- |
| [`docs/rebuild-checklist.md`](docs/rebuild-checklist.md) | **Step-by-step list** from a fresh macOS 27 install to the state above (written so an AI assistant can follow it) |
| [`docs/findings.md`](docs/findings.md) | What was found and how: WindowServer hang, I2C, acpi-path, touchpad freeze, backlight, Finder, Setup Assistant, cryptex, kmutil on 27 |
| [`docs/audio-27.md`](docs/audio-27.md) | Speakers on macOS 27: TAS2781 changes and the VoodooHDA aux KC |
| [`patches/`](patches) | `TAS2781DirectI2C` 0.5.5 patch against the Tahoe repo (wake I2C0 from D3, IC_CON 0x65, start reason in ioreg) |
| [`kexts/`](kexts) | Codeless injectors: `TASAcpiPathInjector`, `GPUAcpiPathInjector`, `I2CAcpiPathInjector` (experimental, freezes) |
| [`docs/wifi-27.md`](docs/wifi-27.md) | Wi-Fi: what is needed, why, step-by-step list, way back, open problems |
| [`docs/bluetooth-27.md`](docs/bluetooth-27.md) | Bluetooth: OpenCore setting, checks and why `IntelBTPatcher` stays off |
| [`docs/airdrop-27.md`](docs/airdrop-27.md) | AirDrop: current findings and open questions |
| [`wifi/`](wifi) | Wi-Fi shims (source), boot service, build/install/remove scripts, OpenCore switch, TCP panic workaround |
| [`scripts/`](scripts) | OpenCore helpers (`oc-kext.sh`, `oc-maxkernel.sh`), aux KC build on Tahoe, offline user, boot capture |

Not included on purpose: TI firmware, the generated TAS2781 tables and any built TAS2781 kext (they contain the
factory calibration of one laptop), NullMoth files, VoodooHDA binaries, logs, the OCLP frameworks and the Wi-Fi kexts.

## Thanks

**NullMoth** for the NVIDIA driver and the whole macOS 27 bring-up; Acidanthera (OpenCore, Lilu, VirtualSMC);
VoodooI2C; VoodooHDA / watchthelight (WTLAudio, LegionI2CArrowLake); the Linux TAS2781, i2c-designware and intel-lpss
drivers; Texas Instruments for the TAS2781 firmware in linux-firmware. See [THIRD-PARTY.md](THIRD-PARTY.md).

## Licence

Own code and files: GPL-2.0 ([LICENSE](LICENSE)), as in the Tahoe project. No affiliation with Apple, ASUS, NVIDIA,
Texas Instruments or NullMoth. Use at your own risk.
