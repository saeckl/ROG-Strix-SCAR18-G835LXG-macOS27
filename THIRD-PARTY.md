# Third-party components

Nothing third-party is redistributed here. The scripts expect, and the docs refer to:

| Component | Source | Licence |
| --- | --- | --- |
| NullMoth NVIDIA driver, a2x, Liberator / 1401 | https://github.com/nullmoth/nvidia-macos-driver | their licence (PolyForm Noncommercial) |
| VoodooHDA (WTLAudio based build) | Tahoe repo `audio/VoodooHDA` | GPL-2.0 |
| VoodooI2C, VoodooI2CHID, VoodooGPIO, VoodooInput | https://github.com/VoodooI2C/VoodooI2C | GPL-2.0 |
| LegionI2CArrowLake | watchthelight | see author |
| TAS2781DirectI2C, ASUSG835WMI, ROG Licht, asus-hotkeys | https://github.com/saeckl/ROG-Strix-SCAR18-G835LXG-macOS | GPL-2.0 |
| AirportItlwm, IO80211FamilyLegacy, IOSkywalkFamily, RTL812xLucy | OpenIntelWireless / AirportItlwm-Tahoe, OCLP, Tahoe EFI | see authors – not included |
| OCLP `IO80211` and `WiFiPeerToPeer` frameworks (Modern Wireless) | OpenCore Legacy Patcher, copied locally from a patched Tahoe | see OCLP – not included |
| TI TAS2781 firmware (`TAS2XXX3F100.bin`, `TIAS2781RCA2.bin`) | linux-firmware `ti/audio/tas2781/` | TI licence – not included |

`kexts/*Injector.kext` only contain an Info.plist and use Apple's `AppleUSBHostMergeProperties` class.
