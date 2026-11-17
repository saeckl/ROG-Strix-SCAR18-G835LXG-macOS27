#!/bin/sh
# Laeuft beim Boot von macOS 27: alle 20 s die "busy"-Dienste und den WindowServer-Zustand festhalten.
OUT=/var/log/ws-debug
rm -rf "$OUT"; mkdir -p "$OUT"
step() { echo "$(date '+%T') $*" >> "$OUT/run.txt"; /bin/sync; }
step "start"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do
  sleep 20
  /usr/sbin/ioreg -w0 -p IOService | /usr/bin/grep -E "busy [1-9]" > "$OUT/busy-$n.txt" 2>&1
  /bin/ps axo pid,stat,etime,command | /usr/bin/grep -E "[W]indowServer|[l]oginwindow" > "$OUT/ps-$n.txt" 2>&1
  step "snapshot $n: $(wc -l < "$OUT/busy-$n.txt" | tr -d ' ') busy, WS: $(awk '/WindowServer/{print $1, $2; exit}' "$OUT/ps-$n.txt")"
done
/usr/sbin/ioreg -w0 -p IOService > "$OUT/ioreg-tree.txt" 2>&1; step "tree done"
