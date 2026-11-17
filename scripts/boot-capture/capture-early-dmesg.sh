#!/bin/sh
# Laeuft beim Boot von macOS 27 (LaunchDaemon local.wsdebug): sichert den Kernel-Puffer moeglichst frueh.
OUT=/var/log/ws-debug
rm -rf "$OUT"; mkdir -p "$OUT"
echo "$(date '+%T') start, msgbuf=$(sysctl -n kern.msgbuf)" >> "$OUT/run.txt"
/sbin/dmesg > "$OUT/dmesg-0.txt" 2>&1; /bin/sync
sleep 60
/sbin/dmesg > "$OUT/dmesg-60.txt" 2>&1; /bin/sync
cat "$OUT"/dmesg-*.txt | /usr/bin/grep -a -i -E "acpi node|NBCI|_DSM|_BCM|_BQC|backlight|brightness|nv_acpi|pwm|eDP|DPCD" | sort -u > "$OUT/backlight-lines.txt"
echo "$(date '+%T') done ($(wc -l < "$OUT/backlight-lines.txt" | tr -d ' ') backlight lines)" >> "$OUT/run.txt"; /bin/sync
