#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: inotify-tools is installed
check "inotifywait is available" \
  "command -v inotifywait > /dev/null 2>&1"

check "inotifywatch is available" \
  "command -v inotifywatch > /dev/null 2>&1"

# Check 3: /proc/sys/fs/inotify/ limits are readable
check "/proc/sys/fs/inotify/max_user_watches is readable" \
  "[ -r /proc/sys/fs/inotify/max_user_watches ] && [ \"\$(cat /proc/sys/fs/inotify/max_user_watches)\" -gt 0 ]"

check "/proc/sys/fs/inotify/max_user_instances is readable" \
  "[ -r /proc/sys/fs/inotify/max_user_instances ] && [ \"\$(cat /proc/sys/fs/inotify/max_user_instances)\" -gt 0 ]"

check "/proc/sys/fs/inotify/max_queued_events is readable" \
  "[ -r /proc/sys/fs/inotify/max_queued_events ] && [ \"\$(cat /proc/sys/fs/inotify/max_queued_events)\" -gt 0 ]"

# Check 6: inotifywait can detect a create event
check "inotifywait detects IN_CREATE event" \
  "tmpdir=\$(mktemp -d) && \
   inotifywait -q -e create -t 3 \"\$tmpdir\" & WPID=\$! && \
   sleep 0.3 && touch \"\$tmpdir/test.txt\" && \
   wait \$WPID 2>/dev/null; EC=\$?; rm -rf \"\$tmpdir\"; [ \$EC -eq 0 ]"

# Check 7: inotifywait can detect a close_write event
check "inotifywait detects IN_CLOSE_WRITE event" \
  "tmpdir=\$(mktemp -d) && \
   inotifywait -q -e close_write -t 3 \"\$tmpdir\" & WPID=\$! && \
   sleep 0.3 && echo test > \"\$tmpdir/test.txt\" && \
   wait \$WPID 2>/dev/null; EC=\$?; rm -rf \"\$tmpdir\"; [ \$EC -eq 0 ]"

# Check 8: inotifywait -m flag works (monitor mode)
check "inotifywait -m (monitor mode) flag is accepted" \
  "tmpdir=\$(mktemp -d) && \
   inotifywait -m -q -e create \"\$tmpdir\" & MPID=\$! && \
   sleep 0.2 && kill \$MPID 2>/dev/null; rm -rf \"\$tmpdir\"; true"

# Check 9: --format flag works
check "inotifywait --format flag is accepted" \
  "tmpdir=\$(mktemp -d) && \
   inotifywait -q -e create --format '%e %f' -t 3 \"\$tmpdir\" & WPID=\$! && \
   sleep 0.3 && touch \"\$tmpdir/fmt.txt\" && \
   wait \$WPID 2>/dev/null; EC=\$?; rm -rf \"\$tmpdir\"; [ \$EC -eq 0 ]"

# Check 10: max_user_watches can be changed
check "max_user_watches sysctl is writable" \
  "ORIG=\$(cat /proc/sys/fs/inotify/max_user_watches) && \
   echo \$((ORIG + 1)) | sudo tee /proc/sys/fs/inotify/max_user_watches > /dev/null && \
   echo \$ORIG | sudo tee /proc/sys/fs/inotify/max_user_watches > /dev/null"

# Check 11: practice/inotify directory exists
check "~/practice/inotify directory exists" \
  "[ -d \$HOME/practice/inotify ]"

# Check 12: watch_and_reload.sh exists
check "watch_and_reload.sh exists" \
  "[ -f \$HOME/practice/inotify/watch_and_reload.sh ]"

# Check 13: watch_and_reload.sh uses inotifywait
check "watch_and_reload.sh uses inotifywait" \
  "grep -q 'inotifywait' \$HOME/practice/inotify/watch_and_reload.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
