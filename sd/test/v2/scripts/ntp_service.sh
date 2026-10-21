#!/bin/sh

CONFIG=/sdcard/test/yi-hack-v2.cfg
PIDFILE=/tmp/yi-hack-ntpd.pid
LOGFILE=/tmp/yi-hack-ntpd.log
DEFAULT_PEER=pool.ntp.org

resolve_ntpd() {
   for candidate in /usr/sbin/ntpd ntpd /sbin/ntpd /usr/bin/ntpd; do
      if command -v "$candidate" >/dev/null 2>&1; then
         printf "%s\n" "$candidate"
         return 0
      fi
   done
   return 1
}

resolve_peer() {
   peer=${YI_HACK_NTP_HOST:-}
   if [ -z "$peer" ] && [ -f "$CONFIG" ]; then
      peer=`sed -n 's/^YI_HACK_NTP_HOST=//p' "$CONFIG" | tail -n 1`
   fi
   if [ -z "$peer" ]; then
      server_cfg=${YI_HACK_NTP_SERVER:-}
      if [ -z "$server_cfg" ] && [ -f "$CONFIG" ]; then
         server_cfg=`sed -n 's/^YI_HACK_NTP_SERVER=//p' "$CONFIG" | tail -n 1`
      fi
      case "$server_cfg" in
         ''|YES|NO) peer=$DEFAULT_PEER ;;
         *) peer=$server_cfg ;;
      esac
   fi
   case "$peer" in
      ''|*[!A-Za-z0-9._:-]*)
         echo "Invalid NTP peer: $peer" >&2
         return 1
         ;;
   esac
   printf "%s\n" "$peer"
}

find_pids() {
   ps 2>/dev/null | grep 'ntpd' | grep -v grep | awk '{print $1}'
}

is_running() {
   [ -n "`find_pids`" ]
}

start_ntp() {
   if is_running; then
      echo "NTP service is already running"
      return 0
   fi
   rm -f "$PIDFILE"
   NTPD=`resolve_ntpd` || {
      echo "ntpd executable was not found" >&2
      return 1
   }
   PEER=`resolve_peer` || return 1
   "$NTPD" -d -n -p "$PEER" >"$LOGFILE" 2>&1 &
   pid=$!
   echo "$pid" > "$PIDFILE"
   sleep 1
   if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PIDFILE"
      echo "NTP service failed to start; see $LOGFILE" >&2
      return 1
   fi
   echo "NTP service started ($PEER)"
}

stop_ntp() {
   for pid in `find_pids`; do
      kill "$pid" 2>/dev/null
   done
   sleep 1
   rm -f "$PIDFILE"
   if is_running; then
      echo "NTP service did not stop" >&2
      return 1
   fi
   echo "NTP service stopped"
}

case "${1:-status}" in
   start) start_ntp ;;
   stop) stop_ntp ;;
   status)
      if is_running; then
         echo "running"
      else
         echo "stopped"
         exit 1
      fi
      ;;
   *)
      echo "Usage: ntp_service.sh {start|stop|status}" >&2
      exit 2
      ;;
esac
