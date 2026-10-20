#!/bin/sh

SERVER=/sdcard/test/v2/audio/audio_rtsp_server
PIDFILE=/tmp/yi-hack-audio-rtsp.pid

find_pids() {
   ps 2>/dev/null | grep "$SERVER" | grep -v grep | awk '{print $1}'
}

is_running() {
   [ -n "`find_pids`" ]
}

start_audio() {
   if is_running; then
      echo "Audio RTSP server is already running"
      return 0
   fi
   rm -f "$PIDFILE"
   if [ ! -x "$SERVER" ]; then
      echo "Audio RTSP server is not installed: $SERVER" >&2
      return 1
   fi
   if [ -x /usr/local/bin/set_audio.sh ]; then
      /usr/local/bin/set_audio.sh >/tmp/yi-hack-audio-codec.log 2>&1 || {
         echo "Audio codec initialization failed; see /tmp/yi-hack-audio-codec.log" >&2
         return 1
      }
   fi
   "$SERVER" >/tmp/yi-hack-audio-rtsp.log 2>&1 &
   pid=$!
   echo "$pid" > "$PIDFILE"
   sleep 1
   if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PIDFILE"
      echo "Audio RTSP server failed to start; see /tmp/yi-hack-audio-rtsp.log" >&2
      return 1
   fi
   echo "Audio RTSP server started"
}

stop_audio() {
   for pid in `find_pids`; do
      kill "$pid" 2>/dev/null
   done
   sleep 1
   rm -f "$PIDFILE"
   if is_running; then
      echo "Audio RTSP server did not stop" >&2
      return 1
   fi
   echo "Audio RTSP server stopped"
}

case "${1:-status}" in
   start) start_audio ;;
   stop) stop_audio ;;
   status)
      if is_running; then
         echo "running"
      else
         echo "stopped"
         exit 1
      fi
      ;;
   *)
      echo "Usage: audio_service.sh {start|stop|status}" >&2
      exit 2
      ;;
esac
