# Exercise: systemd Unit Files

## Tasks

1. **Inspect an existing unit**: Run `systemctl cat ssh` (or `systemctl cat cron`) to view the full unit. Note the Type, ExecStart, Restart policy, and WantedBy. Save the output to `~/practice/unit_ssh.txt`.

2. **Write a unit file**: Create `~/practice/hello.service` with a valid service unit that:
   - Runs `/bin/echo "hello from systemd"` as a oneshot service
   - Has `Description=Hello World Service`
   - Sets `WantedBy=multi-user.target`

3. **Validate the unit**: Run `systemd-analyze verify ~/practice/hello.service` and save any output (even empty = valid) to `~/practice/unit_verify.txt`.

4. **Explore drop-ins**: Run `systemctl cat cron 2>/dev/null || systemctl cat ssh` and check if any `.d/` override files are shown. Save the full `cat` output to `~/practice/unit_dropin.txt`.

5. **Properties**: Run `systemctl show cron --property=MainPID,ActiveState,Restart 2>/dev/null || systemctl show ssh --property=MainPID,ActiveState,Restart` and save to `~/practice/unit_props.txt`.

## Hints

- `systemctl cat` output shows `# /lib/systemd/system/...` headers indicating file sources
- A oneshot Type means the ExecStart runs once and the service is considered active while running
- `systemd-analyze verify` will warn about missing units referenced by Wants/Requires — that's ok for our file
