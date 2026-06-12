# Exercise: systemd Timers

## Tasks

1. **List timers**: Run `systemctl list-timers --all` and save the output to `~/practice/timers_list.txt`. Identify how many timers are active.

2. **Validate calendar specs**: Use `systemd-analyze calendar` to validate these expressions and save results to `~/practice/timer_calendar.txt`:
   - `Mon..Fri 09:00`
   - `*-*-1 00:00`
   - `quarterly`

3. **Write a timer pair**: Create these two files in `~/practice/`:
   - `cleanup.service` — a oneshot service that runs `/usr/bin/find /tmp -mtime +7 -delete`
   - `cleanup.timer` — activates cleanup.service daily at 3am with `Persistent=true`

4. **Inspect an existing timer**: Run `systemctl cat apt-daily.timer 2>/dev/null || systemctl cat logrotate.timer 2>/dev/null || echo "no timer found"` and save to `~/practice/timer_apt_daily.txt`.

## Hints

- `systemd-analyze calendar "spec"` — note the quotes around the spec
- The timer file must have `[Install]` with `WantedBy=timers.target`
- The service filename must match the timer filename (cleanup.service / cleanup.timer)
