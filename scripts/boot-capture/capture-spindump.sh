#!/bin/sh
# Capture 1 (found the hang): ps/wchan, lsof, sample and spindump of WindowServer while it is stuck.
OUT=/var/log/ws-debug
mkdir -p "$OUT"
step() { echo "$(date '+%T') $*" >> "$OUT/run.txt"; /bin/sync; }
step "start"
sleep 75
WS=$(/usr/bin/pgrep -x WindowServer | head -1)
step "WindowServer pid=${WS:-none}"
/bin/ps axo pid,ppid,stat,wchan,etime,command > "$OUT/ps-1.txt" 2>&1; step "ps-1 done"
[ -n "$WS" ] && { /bin/ps -M -p "$WS" > "$OUT/ps-threads-ws.txt" 2>&1; step "ps-threads done"; }
[ -n "$WS" ] && { /usr/sbin/lsof -p "$WS" > "$OUT/lsof-ws.txt" 2>&1; step "lsof done"; }
/usr/bin/log show --last 3m --info --debug --style compact --predicate 'process == "WindowServer" OR (process == "kernel" AND (eventMessage CONTAINS[c] "a2x" OR eventMessage CONTAINS[c] "WindowServer"))' > "$OUT/log-1.txt" 2>&1; step "log-1 done"
sleep 30
/bin/ps axo pid,ppid,stat,wchan,etime,command > "$OUT/ps-2.txt" 2>&1; step "ps-2 done"
[ -n "$WS" ] && { /usr/bin/sample "$WS" 2 -file "$OUT/sample-ws.txt" > "$OUT/sample-ws.log" 2>&1; step "sample done"; }
[ -n "$WS" ] && { /usr/sbin/spindump "$WS" 3 10 -file "$OUT/spindump-ws.txt" -noProcessingWhileSampling > "$OUT/spindump-ws.log" 2>&1; step "spindump done"; }
step "all done"
