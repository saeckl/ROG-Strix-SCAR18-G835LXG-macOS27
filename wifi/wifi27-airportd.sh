#!/bin/bash
# Keeps Wi-Fi working on macOS 27 without touching the system volume. Installed to /Library/WiFi27.
#  1. airportd runs with the OCLP frameworks and the shim.
#  2. WiFiAgent and ControlCenter run with the EAPOL shim (otherwise they hang on the dead service).
#  3. If the driver stops scanning while disconnected, the Wi-Fi interface is reset.
R=/Library/WiFi27; F=$R/oclp-fw; L=$R/libio80211logshim.dylib; E=$R/libeapolshim.dylib
O=/var/log/airportd-wifi27; S=system/com.apple.airportd; IF=""

log() { echo "$(date '+%F %T') $*" >> $O.log; }
cur() { launchctl print "$1" 2>/dev/null | awk '$1=="pid"{print $3; exit}'; }
ours() { [ -n "$1" ] && grep -aq "airportd\[$1:" $O.err 2>/dev/null; }

start_airportd() {
  pkill -f "launchctl debug $S" 2>/dev/null
  [ -s $O.err ] && mv -f $O.err $O.err.prev
  rm -f $O.err $O.out
  launchctl kill SIGKILL $S 2>/dev/null
  sleep 1
  launchctl debug $S --stdout $O.out --stderr $O.err --environment DYLD_INSERT_LIBRARIES=$L DYLD_FRAMEWORK_PATH=$F \
    DYLD_LIBRARY_PATH=$F/IO80211.framework/Versions/A:$F/WiFiPeerToPeer.framework/Versions/A >/dev/null 2>&1 &
  local d=$! i p
  for i in $(seq 1 30); do
    sleep 3
    launchctl kickstart $S >/dev/null 2>&1
    p=$(cur $S)
    if ours "$p"; then
      kill $d 2>/dev/null; wait $d 2>/dev/null
      chmod 644 $O.err $O.out 2>/dev/null
      log "airportd running with OCLP files, pid $p"
      return 0
    fi
  done
  kill $d 2>/dev/null; wait $d 2>/dev/null
  log "ERROR: airportd with OCLP files did not start"
  return 1
}

# Processes whose hang blocks the Wi-Fi menu (rapportd and sharingd crash with the shim). ControlCenter last,
# so that it connects to an already working WiFiAgent.
GUI_JOBS="com.apple.wifi.WiFiAgent com.apple.controlcenter"
agent_next=0
start_gui_job() {
  local j=$1 name=$2 old p d i
  old=$(cur $j)
  launchctl debug $j --environment DYLD_INSERT_LIBRARIES=$E >/dev/null 2>&1 &
  d=$!
  sleep 1
  [ -n "$old" ] && kill -9 "$old" 2>/dev/null
  for i in $(seq 1 15); do
    sleep 2
    launchctl kickstart $j >/dev/null 2>&1
    p=$(cur $j)
    if [ -n "$p" ] && [ -e /tmp/wifi27-eapolshim.$p ]; then
      kill $d 2>/dev/null; wait $d 2>/dev/null
      log "$name running with EAPOL shim, pid $p"
      return 0
    fi
  done
  kill $d 2>/dev/null; wait $d 2>/dev/null
  log "ERROR: $name with EAPOL shim did not start"
  return 1
}
ensure_agent() {
  local u n j p
  u=$(stat -f %u /dev/console 2>/dev/null); [ -n "$u" ] && [ "$u" != 0 ] || return 0
  [ "$(date +%s)" -ge "$agent_next" ] || return 0
  for n in $GUI_JOBS; do
    j=gui/$u/$n; p=$(cur $j)
    [ -n "$p" ] && [ -e /tmp/wifi27-eapolshim.$p ] && continue
    start_gui_job $j $n || agent_next=$(( $(date +%s) + 60 ))
  done
}

last_mark=""; last_change=$(date +%s); last_reset=0
check_driver() {
  local now m
  [ -n "$IF" ] || IF=$(networksetup -listallhardwareports 2>/dev/null | awk "/Wi-Fi/{getline; print \$2; exit}")
  [ -n "$IF" ] || return 0
  now=$(date +%s)
  if ifconfig $IF 2>/dev/null | grep -q "status: active"; then last_change=$now; last_mark=""; return 0; fi
  networksetup -getairportpower $IF 2>/dev/null | grep -q ": On" || { last_change=$now; return 0; }
  m=$(dmesg 2>/dev/null | grep "itlwm: iwx_bz_port_scan" | tail -1 | sed -E 's/^\[ *([0-9.]+)\].*/\1/')
  if [ -n "$m" ] && [ "$m" != "$last_mark" ]; then last_mark=$m; last_change=$now; return 0; fi
  if [ $((now-last_change)) -ge 45 ] && [ $((now-last_reset)) -ge 120 ]; then
    log "driver stopped scanning, resetting $IF"
    ifconfig $IF down; sleep 3; ifconfig $IF up
    last_reset=$now; last_change=$now; last_mark=""
  fi
}

[ -f $L ] && [ -f $E ] && [ -d $F ] || { log "ERROR: files missing in $R"; sleep 3600; exit 1; }
log "service started"
fails=0; good=0
while :; do
  p=$(cur $S)
  if ours "$p"; then
    good=$((good+1)); [ $good -ge 4 ] && fails=0
    ensure_agent
    check_driver
    sleep 15
    continue
  fi
  good=0
  log "airportd without OCLP files or gone (pid ${p:-none}), restarting"
  start_airportd || fails=$((fails+1))
  # Guard against an endless loop if airportd keeps crashing
  p=$(cur $S); ours "$p" || fails=$((fails+1))
  if [ $fails -ge 5 ]; then log "too many failures, pausing 5 minutes"; sleep 300; fails=0; else sleep 5; fi
done
