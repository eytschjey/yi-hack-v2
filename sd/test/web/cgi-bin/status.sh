#!/bin/sh

CONFIG=/sdcard/test/yi-hack-v2.cfg
if [ -z "${TZ:-}" ] && [ -f "$CONFIG" ]; then
   tz_cfg=`sed -n 's/^YI_HACK_TIME_TIMEZONE=//p' "$CONFIG" | tail -n 1`
   if [ -n "$tz_cfg" ]; then
      TZ=$tz_cfg
      export TZ
   fi
fi

printf "Content-Type: text/plain\r\n"
printf "Cache-Control: no-store\r\n\r\n"
printf "Yi Hack v2 status\n"
printf "Date: %s\n" "`date`"
printf "Uptime: "
cat /proc/uptime 2>/dev/null || printf "unavailable\n"
printf "Load: "
cat /proc/loadavg 2>/dev/null || printf "unavailable\n"
printf "\nMemory:\n"
grep -E '^(MemTotal|MemFree|Buffers|Cached):' /proc/meminfo 2>/dev/null
printf "\nNetwork:\n"
ifconfig 2>/dev/null
printf "\nServices:\n"
for service in "rtsp_server:RTSP" "httpd:HTTP"; do
   process="${service%%:*}"
   label="${service#*:}"
   if ps 2>/dev/null | grep "$process" | grep -v grep >/dev/null 2>&1; then
      printf "%s: running\n" "$label"
   else
      printf "%s: stopped\n" "$label"
   fi
done
if [ -x /sdcard/test/v2/scripts/audio_service.sh ] &&
   /sdcard/test/v2/scripts/audio_service.sh status >/dev/null 2>&1; then
   printf "Audio RTSP: running\n"
else
   printf "Audio RTSP: stopped\n"
fi
if grep '^YI_HACK_AUDIO_RTSP_SERVER=YES$' /sdcard/test/yi-hack-v2.cfg >/dev/null 2>&1; then
   printf "Audio RTSP setting: YES\n"
else
   printf "Audio RTSP setting: NO\n"
fi
if [ -x /sdcard/test/v2/scripts/ntp_service.sh ] &&
   /sdcard/test/v2/scripts/ntp_service.sh status >/dev/null 2>&1; then
   printf "NTP: running\n"
else
   printf "NTP: stopped\n"
fi
if grep '^YI_HACK_NTP_SERVER=NO$' /sdcard/test/yi-hack-v2.cfg >/dev/null 2>&1; then
   printf "NTP setting: NO\n"
else
   printf "NTP setting: YES\n"
fi
printf "\nVideo processes:\n"
ps 2>/dev/null | grep -E 'test_encode|test_tuning|rtsp_server' | grep -v grep
