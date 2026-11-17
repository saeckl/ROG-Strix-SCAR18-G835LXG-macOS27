# Boot capture for macOS 27 (run from the working macOS)

`install.sh` puts a LaunchDaemon (`local.wsdebug`) and `/Library/WSDebug/ws-debug.sh` on the **macOS 27 data volume only**.
Copy the capture you want to `ws-debug.sh` first. Output lands in `/var/log/ws-debug` on the macOS 27 data volume.

| Script | What it records |
| --- | --- |
| `capture-spindump.sh` | ps/wchan, lsof, `sample` and `spindump` of WindowServer while it is stuck (found `IOKitWaitQuiet`) |
| `capture-ioreg-busy.sh` | every 20 s: IOKit services with `busy N` + WindowServer state (found the busy I2C controllers) |
| `capture-early-dmesg.sh` | kernel message buffer right at daemon start and after 60 s (early kext output never reaches the unified log on 27) |

Remove with `remove.sh`. Run the scripts with `sudo`.
