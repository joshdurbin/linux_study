# Exercise: lsof Deep

## Tasks

1. **Network snapshot**: Run `lsof -i TCP -sTCP:LISTEN -nP 2>/dev/null` to list all TCP listeners. Save to `~/practice/lsof_listeners.txt`. If empty, run `lsof -i` and save that instead.

2. **Process FD count**: Count open file descriptors for your current shell:
   ```bash
   echo "Shell PID: $$" > ~/practice/lsof_shell_fds.txt
   lsof -p $$ 2>/dev/null >> ~/practice/lsof_shell_fds.txt
   echo "Total FDs: $(ls /proc/$$/fd | wc -l)" >> ~/practice/lsof_shell_fds.txt
   ```

3. **File ownership**: Pick a log file that likely exists (`/var/log/dpkg.log` or `/var/log/auth.log`) and find which processes have it open:
   ```bash
   LOGFILE=$(ls /var/log/*.log 2>/dev/null | head -1)
   lsof "$LOGFILE" 2>/dev/null > ~/practice/lsof_logfile.txt || \
     echo "no process has $LOGFILE open" > ~/practice/lsof_logfile.txt
   ```

4. **Deleted files hunt**: Find any deleted files still being held open:
   ```bash
   sudo lsof +L1 2>/dev/null | head -20 > ~/practice/lsof_deleted.txt || \
     lsof +L1 2>/dev/null | head -20 > ~/practice/lsof_deleted.txt || \
     echo "no deleted-but-open files found (or lsof requires root)" > ~/practice/lsof_deleted.txt
   ```

5. **FD limits**: Check the open file limit for a running process:
   ```bash
   cat /proc/$$/limits | grep -i "open files" > ~/practice/lsof_limits.txt
   cat /proc/sys/fs/file-nr >> ~/practice/lsof_limits.txt
   ```

## Hints

- `lsof -nP` skips DNS resolution (`-n`) and port name lookup (`-P`) for speed
- `+L1` finds files with link count below 1 — i.e., unlinked (deleted) but still open
- `/proc/sys/fs/file-nr` shows `used  unused  max` — the first column is system-wide FDs in use
