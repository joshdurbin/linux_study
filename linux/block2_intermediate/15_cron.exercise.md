# Exercise: cron

## Tasks

1. **Read existing cron config**: Examine what's already scheduled:
   ```bash
   echo "=== /etc/crontab ===" > ~/practice/cron_inventory.txt
   cat /etc/crontab >> ~/practice/cron_inventory.txt
   echo "=== /etc/cron.d/ ===" >> ~/practice/cron_inventory.txt
   ls -la /etc/cron.d/ >> ~/practice/cron_inventory.txt
   echo "=== /etc/cron.daily/ ===" >> ~/practice/cron_inventory.txt
   ls /etc/cron.daily/ >> ~/practice/cron_inventory.txt
   ```

2. **Add a crontab entry**: Add a job to your user crontab that writes a timestamp every minute to a log file:
   ```bash
   (crontab -l 2>/dev/null; echo "* * * * *  date >> /tmp/cron_test.log") | crontab -
   crontab -l > ~/practice/cron_mine.txt
   ```
   Wait ~70 seconds, then:
   ```bash
   cat /tmp/cron_test.log > ~/practice/cron_ran.txt 2>/dev/null || \
     echo "cron may not be running in this container" > ~/practice/cron_ran.txt
   ```

3. **Write cron expressions**: Write `~/practice/cron_expressions.txt` with crontab lines for:
   - Every 15 minutes
   - Weekdays at 8:30am
   - First of every month at midnight
   - Every Sunday at 2am
   - @reboot

4. **Cron environment test**: Add a cron job that captures the cron environment to a file (or write what it would look like):
   ```bash
   cat > ~/practice/cron_env_job.txt << 'EOF'
   # This crontab entry captures cron's minimal environment:
   MAILTO=""
   * * * * *  env > /tmp/cron_env.txt 2>&1
   
   # Expected output: PATH=/usr/bin:/bin (no user PATH)
   # Always use absolute paths in cron commands
   EOF
   ```

5. **Clean up**: Remove the test cron entry:
   ```bash
   crontab -l 2>/dev/null | grep -v "cron_test.log" | crontab - 2>/dev/null || true
   echo "cleanup done" >> ~/practice/cron_mine.txt
   ```

## Hints

- `(crontab -l 2>/dev/null; echo "new line") | crontab -` is the safe idiom for appending
- cron may not be running in a container without a proper init system — test with `systemctl status cron`
- `@reboot` is great for tasks that need to run once after each boot but don't fit `rc.local`
