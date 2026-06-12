# Exercise: inotify and Filesystem Events

## Setup

```bash
mkdir -p ~/practice/inotify/watched
sudo apt-get install -y inotify-tools 2>/dev/null || true
```

## Task 1: Check inotify Kernel Limits

```bash
echo "=== inotify Kernel Limits ==="
echo "max_user_watches:   $(cat /proc/sys/fs/inotify/max_user_watches)"
echo "max_user_instances: $(cat /proc/sys/fs/inotify/max_user_instances)"
echo "max_queued_events:  $(cat /proc/sys/fs/inotify/max_queued_events)"
```

## Task 2: Basic inotifywait — Wait for One Event

```bash
# Watch for a file creation event (wait in background, trigger it)
inotifywait -q -e create ~/practice/inotify/watched/ &
WAIT_PID=$!

# Trigger the event
sleep 0.5
touch ~/practice/inotify/watched/trigger.txt

# Wait for inotifywait to report and exit
wait $WAIT_PID
echo "Event detected!"
```

## Task 3: Monitor Mode — Continuous Watching

```bash
# Start watching in monitor mode in background
inotifywait -m -q \
    -e create,delete,modify,close_write \
    --format '%e %f' \
    ~/practice/inotify/watched/ &
MONITOR_PID=$!

sleep 0.5

# Generate several events
echo "hello" > ~/practice/inotify/watched/file1.txt       # CREATE + CLOSE_WRITE
echo "world" >> ~/practice/inotify/watched/file1.txt      # MODIFY + CLOSE_WRITE
cp ~/practice/inotify/watched/file1.txt ~/practice/inotify/watched/file2.txt
rm ~/practice/inotify/watched/trigger.txt                  # DELETE

sleep 1
kill $MONITOR_PID 2>/dev/null
echo "Monitor stopped"
```

## Task 4: Watch for Specific Event Types

```bash
# Only close_write events (file done being written to)
inotifywait -m -q -e close_write \
    --format 'WRITTEN: %w%f' \
    ~/practice/inotify/watched/ &
CW_PID=$!

sleep 0.3
echo "test" > ~/practice/inotify/watched/write_test.txt   # triggers close_write
echo "append" >> ~/practice/inotify/watched/write_test.txt

sleep 1
kill $CW_PID 2>/dev/null
```

## Task 5: inotifywait with Timestamp Format

```bash
inotifywait -m -q \
    -e create,delete,modify \
    --format '%T %e %f' \
    --timefmt '%H:%M:%S' \
    ~/practice/inotify/watched/ &
TS_PID=$!

sleep 0.3
touch ~/practice/inotify/watched/ts_test.txt
rm ~/practice/inotify/watched/ts_test.txt

sleep 1
kill $TS_PID 2>/dev/null
```

## Task 6: Auto-Action on File Change

```bash
# Watch for changes to a config file and "reload" on write
cat > ~/practice/inotify/watched/config.txt << 'EOF'
# config v1
timeout = 30
EOF

# Start the watcher
cat > ~/practice/inotify/watch_and_reload.sh << 'EOF'
#!/bin/bash
CONFIG=~/practice/inotify/watched/config.txt
echo "Watching $CONFIG for changes..."
COUNT=0
while inotifywait -q -e close_write "$CONFIG" 2>/dev/null; do
    COUNT=$((COUNT + 1))
    echo "Config changed (reload #$COUNT): $(cat $CONFIG | grep -v '^#')"
    [ $COUNT -ge 2 ] && break    # stop after 2 reloads for the exercise
done
echo "Done."
EOF
chmod +x ~/practice/inotify/watch_and_reload.sh

# Run the watcher in background
bash ~/practice/inotify/watch_and_reload.sh &
RELOAD_PID=$!

sleep 0.5
echo "# config v2" > ~/practice/inotify/watched/config.txt
echo "timeout = 60" >> ~/practice/inotify/watched/config.txt

sleep 0.5
echo "# config v3" > ~/practice/inotify/watched/config.txt
echo "timeout = 90" >> ~/practice/inotify/watched/config.txt

wait $RELOAD_PID 2>/dev/null
```

## Task 7: Count Events with inotifywatch

```bash
echo "Watching for 5 seconds — generate some events..."
inotifywatch -t 5 -q ~/practice/inotify/watched/ &
WATCH_PID=$!

sleep 0.5
for i in 1 2 3 4 5; do
    echo "data $i" > ~/practice/inotify/watched/count_test_$i.txt
done
rm ~/practice/inotify/watched/count_test_*.txt 2>/dev/null

wait $WATCH_PID
```

## Task 8: Adjust Watch Limits

```bash
echo "Current max_user_watches: $(cat /proc/sys/fs/inotify/max_user_watches)"

# Increase (requires root)
echo 65536 | sudo tee /proc/sys/fs/inotify/max_user_watches > /dev/null

echo "New max_user_watches: $(cat /proc/sys/fs/inotify/max_user_watches)"

# Restore
echo 8192 | sudo tee /proc/sys/fs/inotify/max_user_watches > /dev/null
echo "Restored: $(cat /proc/sys/fs/inotify/max_user_watches)"
```

## Expected Outcome

- `/proc/sys/fs/inotify/` limits are readable
- `inotifywait` detects file creation, modification, and deletion events
- Monitor mode (`-m`) watches continuously until killed
- `--format` produces customized event output with timestamps
- `inotifywatch` counts events over a time period
- `watch_and_reload.sh` triggers an action on config file changes
