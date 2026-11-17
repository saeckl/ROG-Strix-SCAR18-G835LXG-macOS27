# Findings on macOS 27.2 beta (26B123)

Log times in macOS 27 logs are PST. Tools that helped: a LaunchDaemon on the 27 data volume that writes ps/ioreg/spindump/dmesg
to `/var/log/ws-debug` ([scripts/boot-capture](../scripts/boot-capture)), read back from Tahoe.

## 1. WindowServer waits forever in IOKitWaitQuiet

Symptom: verbose text stops, prohibitory sign, no desktop. WindowServer runs but `nvload` says "drew no frame in 210 s".

- `ps`: WindowServer in state `U`, 0.05 s CPU, no log line, `com.apple.windowserver.active` never registered,
  no IOUserClients on NVAccel / NVRMFB.
- spindump (all 308 samples):
  `__arm2x86_interp_native → SLXServer → WSInitialize → __WSWaitForIOKitReady_block_invoke → IOKitWaitQuiet → io_service_wait_quiet`.
- ioreg `busy` while waiting: only `I2C0@15` (8086:7f4c) and `I2C4@19` (8086:7f7a), both `!matched, busy 1`
  (everything above them is busy only because of them).
- Cause: in the OpenCore config VoodooI2C and its plugins had MaxKernel 26.99.99, but the **codeless
  `LegionI2CArrowLake.kext` had none**. On Darwin 27 its personalities (VoodooI2CPCILakeController for 7f4c/7f7a) were
  there without VoodooI2C → matching never finished → the registry never went quiet.
- Fix: same MaxKernel for both (either way). Boot then takes ~4–5 min after the kernel text.

## 2. Setup Assistant crash

`EXC_ARITHMETIC / SIGFPE` (divide by zero) on queue `com.apple.avatarkit.AVTStickerGenerator`, inside VFX, called from
`-[AVTSnapshotHelper newCGImageWithRenderer:antialiasingMode:pixelWidth:pixelHeight:error:]`; machine restarts a minute later.
Workaround: create the account offline ([create-user-offline.sh](../scripts/create-user-offline.sh)).

## 3. Touchpad: VoodooI2C needs acpi-path, then freezes

- `VoodooI2CPCIController::start()` reads the **OSString `acpi-path`** of the PCI nub and resolves it with
  `IORegistryEntry::fromPath`; no fallback ("Could not get ACPI device for PCI provider"). Children (TPD0, TAS_) are
  found through that ACPI node.
- Under NullMoth's `A2XACPIPCI` **no PCI nub has `acpi-path` or `acpi-device`** (0 in the whole IOService plane).
  The ACPI nodes exist: `IOACPIPlane:/_SB_/PC02@0/I2C0@150000` (TAS_), `…/I2C4@190000` (TPD0) – note `_SB_`, not `_SB`.
- A codeless kext with `IOClass AppleUSBHostMergeProperties` + `IOProviderMergeProperties {acpi-path}` (score 20000, own
  `IOMatchCategory`) puts the path on the nub (plain `IOClass IOService` does **not** merge). VoodooI2C then attaches –
  and macOS 27 **freezes hard** (no panic). I2C4 alone is enough; ws-gate's `sysctl -w debug.nvaccelfb=1` never returns.
  Probably a shared resource between VoodooI2C (PCI PM D3→D0, polling, GPIO via NetArm2x86IOAPIC) and NVAccel. Open.

## 4. Display brightness

- Without `acpi-path` on the GPU, NVRM does not find its ACPI node (`IOACPIPlane:/_SB_/PC00@0/RP01@60000/PXSX@0`): "no NVKMS
  backlight", falls back to eDP AUX (DPCD 0x701=0x83 0x702=0x87), every set fails with `0xe00002ca`.
- With `GPUAcpiPathInjector`: `NBCI _DSM` runs, NVKMS "backlight registered: gpu 0x200 display 0x200 at 100%", every slider step
  "applied … hardware=X%" – **exactly as on Tahoe**, also no extra kernel line on Tahoe while sliding. The panel still does not change on 27.
  The difference is below anything that logs. Open (NullMoth).

## 5. Finder crash when a device appears

`EXC_BAD_ACCESS`, trap 14 "invalid protections for user instruction read", rip == fault address inside thread 0's own stack.
Path: DesktopServices notification → `NSOutlineView reloadItem` (sidebar) → `makeViewForTableColumn` → `__arm2x86_call_rf` /
`ffi_closure` → jump into the stack (`_sigtramp` in the stack). Unticking sidebar items does not help; **hiding the sidebar** does.

## 6. Speakers

See [audio-27.md](audio-27.md). Short: TAS2781DirectI2C needs the Tahoe-style `acpi-path` string on I2C0, must wake I2C0 from D3
itself (VoodooI2C did it on Tahoe) and must set `IC_CON` to `0x65` (firmware leaves `0x77` = high-speed, 10-bit → nothing is sent).

## 7. Other notes

- **kmutil on 27** reads KC UUIDs wrong (e.g. system KC "linked against …FE10-357300A00050", boot KC "…FE40-4B5F00800050"):
  aux KCs must be built on Tahoe. Without `--volume-root`, with `-x -b <ids>`, check `_BootKCID`.
- **NullMoth's 27 aux KC** ships prebuilt; after an OS update its `_BootKCID` no longer matches → `auxkcload` refuses it and it
  is removed. Install 27 fresh instead of "Prepare" over an old install.
- **Cryptex:** Tahoe and 27 share `Preboot/Cryptexes/OS` (Tahoe's x86_64 dyld cache). Pointing 27 to its own arm64e cryptex
  made things worse (a2x scripts stopped) → the shared x86 cryptex is what a2x expects.
- **python3** on 27 fails in its stub (`posix_spawn … Undefined error`); the framework executable works when called directly.
- Shutdown cause on this machine is always reported as 5 (VirtualSMC) – not useful.
- NVRAM reset is not needed between tests: boot-args and csr are deleted and re-added from `config.plist` each boot.
