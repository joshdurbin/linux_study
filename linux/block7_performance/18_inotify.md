# inotify and fanotify — Filesystem Event Watching

`inotify` allows processes to subscribe to filesystem events on files and directories — creation, modification, deletion, moves. It's the mechanism behind file-watching daemons, live-reload in development servers, backup tools, and log shippers.

## How inotify Works

```
Application                          Kernel
inotify_init1() → fd                 ←→ inotify subsystem
inotify_add_watch(fd, path, mask)    ←  registers watch
                                         ↓ (event occurs on path)
read(fd, buf, size)          ←  inotify_event structs are delivered
```

Three syscalls:
- `inotify_init1` — create an inotify instance (returns a file descriptor)
- `inotify_add_watch` — start watching a path for specific events
- `inotify_remove_watch` — stop watching

Events are read from the FD like a stream of `inotify_event` structs. This integrates with `epoll`/`select`/`poll` naturally.

## inotify Events

| Event | Constant | Meaning |
|-------|---------|---------|
| File accessed | `IN_ACCESS` | `read()` called on file |
| File modified | `IN_MODIFY` | `write()` or `truncate()` |
| Attributes changed | `IN_ATTRIB` | chmod, chown, touch |
| File closed (write) | `IN_CLOSE_WRITE` | File opened for write, then closed |
| File closed (no write) | `IN_CLOSE_NOWRITE` | File opened read-only, then closed |
| File opened | `IN_OPEN` | `open()` called |
| File/dir moved from | `IN_MOVED_FROM` | Rename — source side |
| File/dir moved to | `IN_MOVED_TO` | Rename — destination side |
| File created | `IN_CREATE` | File or dir created in watched dir |
| File deleted | `IN_DELETE` | File or dir deleted from watched dir |
| Watched item deleted | `IN_DELETE_SELF` | The watched file itself was deleted |
| Watched item moved | `IN_MOVE_SELF` | The watched file itself was moved |

### Composite Events

| Macro | Equivalent to |
|-------|--------------|
| `IN_CLOSE` | `IN_CLOSE_WRITE | IN_CLOSE_NOWRITE` |
| `IN_MOVE` | `IN_MOVED_FROM | IN_MOVED_TO` |
| `IN_ALL_EVENTS` | All of the above |

## inotifywait — Command-Line inotify Interface

`inotifywait` (from the `inotify-tools` package) provides a convenient CLI for watching filesystem events.

```bash
# Install inotify-tools
sudo apt-get install -y inotify-tools

# Wait for any event on a file (blocks until event occurs)
inotifywait /etc/hosts

# Watch a directory for any event
inotifywait -r /var/log/

# Watch for specific events only
inotifywait -e create,delete,modify /tmp/

# Watch in monitor mode (continuous, don't exit after first event)
inotifywait -m -e close_write /var/log/syslog

# Monitor mode with quiet output + format
inotifywait -m -q -e create,delete --format '%T %e %f' --timefmt '%H:%M:%S' /tmp/

# Watch a file for modifications and take action
while inotifywait -e close_write /etc/nginx/nginx.conf; do
    nginx -t && nginx -s reload
done
```

### Recursive Directory Watch

```bash
# Watch an entire directory tree (use -r)
inotifywait -m -r /var/www/html/ -e create,delete,modify \
    --format '%T %w%f %e' --timefmt '%H:%M:%S'
```

The `-r` flag watches all subdirectories. For large trees (>8192 directories), you may hit the watch limit.

## inotifywatch — Event Count Statistics

```bash
# Count events over a time period
inotifywatch -t 30 -r /var/log/
# Watches /var/log/ for 30 seconds and prints a table of event counts per file
```

## Watch Limits

inotify watches have kernel limits:

```bash
# Maximum number of watches per user
cat /proc/sys/fs/inotify/max_user_watches      # default: 8192

# Maximum number of inotify instances per user
cat /proc/sys/fs/inotify/max_user_instances    # default: 128

# Maximum size of the event queue
cat /proc/sys/fs/inotify/max_queued_events     # default: 16384

# Increase watch limit (needed for large codebases — e.g., webpack, VS Code)
echo 524288 | sudo tee /proc/sys/fs/inotify/max_user_watches
# Persist:
echo "fs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/99-inotify.conf
```

## Practical Patterns

```bash
# Live-reload: restart a service when its config changes
while inotifywait -e close_write /etc/myapp/config.yaml; do
    systemctl reload myapp
done &

# Log rotation watcher: alert when log file is truncated
inotifywait -m -e move_self,delete_self /var/log/app.log

# File integrity monitoring: watch /etc for unauthorized changes
inotifywait -m -r /etc/ -e create,delete,modify,attrib \
    --format '%(T)T %(w)s%(f)s %(e)s' --timefmt '%Y-%m-%d %H:%M:%S' \
    >> /var/log/etc_changes.log &

# Auto-compile: rebuild when source files change
inotifywait -m -r ./src/ -e close_write --include '\.go$' \
    --format '%f' | while read file; do
    go build ./...
    echo "Rebuilt after change to $file"
done
```

## fanotify — Enhanced Filesystem Monitoring

`fanotify` (5.1+) is the successor for use cases requiring:
- **Pre-event notification** — can allow or deny an operation before it completes
- **Whole-filesystem watching** — watch a mount point, not individual paths
- **Content scanning** — antivirus, DLP (file access can be intercepted)

```bash
# fanotify is not exposed via inotify-tools — requires C code or specialized tools
# It's used internally by: systemd (service tracking), GNOME Tracker, antivirus daemons

# Check fanotify kernel support
grep CONFIG_FANOTIFY /boot/config-$(uname -r) 2>/dev/null | head -3
```

## Further Reading

- [inotify(7) man page](https://man7.org/linux/man-pages/man7/inotify.7.html) — The authoritative reference for all `IN_*` event flags, the `inotify_event` struct layout, queue overflow (`IN_Q_OVERFLOW`), and the `max_user_watches` / `max_queued_events` kernel limits.
- [inotify_add_watch(2) man page](https://man7.org/linux/man-pages/man2/inotify_add_watch.2.html) — Documents the three inotify syscalls (`inotify_init1`, `inotify_add_watch`, `inotify_rm_watch`), the mask bitmask semantics, and the watch descriptor returned for event correlation.
- [fanotify(7) man page](https://man7.org/linux/man-pages/man7/fanotify.7.html) — Documents the enhanced filesystem monitoring API that supports pre-event permission decisions and whole-filesystem watching — the production-grade successor to inotify for security tools.
- [LWN: Filesystem notification](https://lwn.net/Articles/604686/) — LWN article comparing inotify and fanotify, explaining when each is appropriate and the kernel implementation differences between the two event delivery mechanisms.
