# Codeless injectors

All three use Apple's `AppleUSBHostMergeProperties` (plain `IOService` does not merge `IOProviderMergeProperties`), score 20000,
own `IOMatchCategory`, so they do not take the device away from other drivers. Install with `scripts/oc-kext.sh add` (Darwin 27 only).

| Kext | Device | Puts on the nub | Use |
| --- | --- | --- | --- |
| `TASAcpiPathInjector` | I2C0 `8086:7f4c` | `acpi-path = IOACPIPlane:/_SB/PC02@0/I2C0@150000` (Tahoe spelling, what TAS2781DirectI2C compares) | **needed for speakers** |
| `GPUAcpiPathInjector` | GPU `10de:2c58` | `acpi-path = IOACPIPlane:/_SB_/PC00@0/RP01@60000/PXSX@0` | optional, NVKMS backlight registers (panel still fixed) |
| `I2CAcpiPathInjector` | I2C0 + I2C4 | real `_SB_` paths for VoodooI2C | **experimental – macOS 27 freezes** |
