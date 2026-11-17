# Speakers on macOS 27

Hardware and the Tahoe solution: [Tahoe repo, docs/audio-tas2781.md](https://github.com/saeckl/ROG-Strix-SCAR18-G835LXG-macOS/blob/main/docs/audio-tas2781.md).
On 27 the same two parts are needed (VoodooHDA for the ALC285, TAS2781DirectI2C for the amplifiers), with these differences.

## Amplifiers – TAS2781DirectI2C 0.5.5

| Problem on 27 | Fix |
| --- | --- |
| `start()` requires `acpi-path == "IOACPIPlane:/_SB/PC02@0/I2C0@150000"` (string compare); A2XACPIPCI sets none | `kexts/TASAcpiPathInjector.kext` merges exactly that string (Tahoe spelling `_SB`). VoodooI2C cannot resolve it on 27 (`_SB_` there) and stays off I2C0 – no freeze |
| on Tahoe VoodooI2C woke I2C0 first; on 27 nobody does | patch: PCI PM → D0, memory decoding on, LPSS reset deassert (`0x204 := 7`) if the component type does not read `0x44570140` |
| firmware leaves `IC_CON = 0x77` (high-speed, 10-bit master) → TX FIFO never drains, timeout without abort | patch: always `IC_CON := 0x65` (Linux), keep firmware FS counts (75/163), SDA hold ≥ 42 ns |
| failures invisible (early kext output not in the unified log) | patch: start reason as `TAS2781DirectI2C-start` on the I2C0 nub, transfer failure step/status in the `TAS2781Direct` dictionary |

Good state after boot: `TAS2781DirectI2C-start = "started, comp 44570140, before: con 77 fs 75/163 hold 1, now: con 75 fs 75/163"`,
`State = "auto: initialized"`, `Initialized = 1`, `CalNominal38/39` set. `NACK3A_Abort` is expected (0x3A does not ACK).

Build on 27 with the Command Line Tools (clang runs through a2x and produces x86_64 kexts fine); see the checklist for the
Python path. The built kext contains this laptop's factory calibration – do not share it.

## Codec – VoodooHDA in the 27 aux KC

VoodooHDA links against `IOAudioFamily` (system KC), so OpenCore cannot inject it. It must be in the auxiliary KC, which on 27
belongs to NullMoth (NVAccel, NVRMFB, NVRMAGDC, NMXAudio). Build a new one on Tahoe with
[`scripts/aux-kc-voodoohda-on-tahoe.sh`](../scripts/aux-kc-voodoohda-on-tahoe.sh); `auxkcload` then reports "5 of 5 extension(s) running".

Result: "Realtek ALC285: Speaker / Headphones / Microphone", speakers with both amplifiers.
