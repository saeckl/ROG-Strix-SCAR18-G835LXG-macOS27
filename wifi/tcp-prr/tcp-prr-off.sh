#!/bin/sh
# Turns TCP PRR off: avoids the kernel panic (division by zero in tcp_prr_update).
LOG=/var/log/tcp-prr-off.log
echo "$(date '+%F %T') before: $(/usr/sbin/sysctl -n net.inet.tcp.prr 2>&1)" >> "$LOG"
/usr/sbin/sysctl -w net.inet.tcp.prr=0 >> "$LOG" 2>&1
echo "$(date '+%F %T') after: $(/usr/sbin/sysctl -n net.inet.tcp.prr 2>&1)" >> "$LOG"
