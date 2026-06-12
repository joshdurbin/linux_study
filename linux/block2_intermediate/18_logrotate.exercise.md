# Exercise: logrotate

## Tasks

1. **Read existing configs**: Examine what's configured on the system:
   ```bash
   echo "=== Global config ===" > ~/practice/logrotate_inventory.txt
   cat /etc/logrotate.conf >> ~/practice/logrotate_inventory.txt
   echo "=== Drop-in files ===" >> ~/practice/logrotate_inventory.txt
   ls /etc/logrotate.d/ >> ~/practice/logrotate_inventory.txt
   echo "=== Status (last rotations) ===" >> ~/practice/logrotate_inventory.txt
   cat /var/lib/logrotate/status 2>/dev/null | head -20 >> ~/practice/logrotate_inventory.txt
   ```

2. **Dry run**: Run logrotate in debug mode to see what it would do:
   ```bash
   sudo logrotate -dv /etc/logrotate.conf 2>&1 | head -50 > ~/practice/logrotate_dryrun.txt
   ```

3. **Write a config**: Create `~/practice/myapp.logrotate` — a logrotate config for `/var/log/myapp/app.log` that:
   - Rotates daily
   - Keeps 30 rotated copies
   - Compresses with delaycompress
   - Uses dateext suffix
   - Runs `kill -USR1 $(cat /var/run/myapp.pid)` as postrotate
   - Uses missingok and notifempty

4. **Force a rotation**: Create a test log file and rotate it:
   ```bash
   sudo mkdir -p /var/log/logrotate_test
   echo "test log entry $(date)" | sudo tee /var/log/logrotate_test/test.log

   sudo tee /etc/logrotate.d/test_exercise << 'EOF'
   /var/log/logrotate_test/*.log {
       rotate 3
       compress
       missingok
       notifempty
   }
   EOF

   sudo logrotate -f /etc/logrotate.d/test_exercise
   ls -la /var/log/logrotate_test/ > ~/practice/logrotate_result.txt
   sudo rm /etc/logrotate.d/test_exercise  # cleanup
   ```

5. **Journal size**: Check and document journal disk usage:
   ```bash
   journalctl --disk-usage > ~/practice/journal_usage.txt
   grep -E "^(SystemMaxUse|SystemKeepFree|MaxRetentionSec)" /etc/systemd/journald.conf 2>/dev/null \
     >> ~/practice/journal_usage.txt || echo "journald.conf: default settings" >> ~/practice/journal_usage.txt
   ```

## Hints

- `logrotate -d` is non-destructive — always test new configs with it first
- `delaycompress` is needed when a running process still has the log file open — compression happens on the next rotation cycle
- The `postrotate` script runs with the working directory set to `/` — use absolute paths
