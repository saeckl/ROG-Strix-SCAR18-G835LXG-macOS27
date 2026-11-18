# AirDrop on macOS 27: open problem

Status on macOS 27.2 beta (26B123), a2x r27: **AirDrop does not work.** It finds nobody and is not found, even with two active
Apple devices nearby. Bluetooth pairing, BLE scanning and Wi-Fi work. `awdl0` is up, and `sharingd` starts its AirDrop listener.

| `sharingd` state | Result |
| --- | --- |
| Normal | one thread hangs reading the Wi-Fi state, in `EAPOLControlCopyStateAndStatus` |
| With the EAPOL shim from [`wifi/`](../wifi) | no hang, but it crashed after 3, 9 and 21 seconds with AirDrop open |

The hang has the same cause as in the [Wi-Fi guide](wifi-27.md): x86_64 `configd` cannot load the arm64e-only `EAPOLController.bundle`, so
`com.apple.network.EAPOLController` never answers.

The crashes are reported by a2x:

```text
a2x-stop: signal SIGSEGV fault 0x0
a2x-stop: signal SIGABRT fault 0x7ff806dc4bc6
a2x-stop: guest pc sharingd+0x58f374 lr sharingd+0xd2d14
a2x-stop: frame 2 native libobjc.A.dylib+0x2e237 _ZL12_objc_fatalvyyPKcP13__va_list_tag+0x72
```

`sharingd` also exits with 139 without the shim, so the shim is not necessarily the only trigger. It stays out of the boot service.

Not proven: whether AWDL exchanges frames with peers. AirportItlwm 2.0.0 contains AWDL code and the kernel AWDL manager is active, but
this cannot be judged while `sharingd` is unstable. Next step: NullMoth needs to look at the a2x crash and the missing EAPOL service.
