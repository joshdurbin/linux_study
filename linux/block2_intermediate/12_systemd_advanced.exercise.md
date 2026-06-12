# Exercise: systemd Analyze, Sockets, and Advanced Patterns

## Tasks

1. **Boot analysis**: Run `systemd-analyze` and `systemd-analyze blame | head -15`. Save both outputs to `~/practice/systemd_analyze.txt`.

2. **Critical chain**: Run `systemd-analyze critical-chain` and save the output to `~/practice/systemd_critical_chain.txt`.

3. **Socket inventory**: Run `systemctl list-sockets` and save the output to `~/practice/systemd_sockets.txt`.

4. **Write an instantiated template**: Create `~/practice/worker@.service` — a template unit for a hypothetical worker process. Include:
   - `Description=Worker %i`
   - `ExecStart=/usr/bin/echo "Starting worker %i"` (Type=oneshot)
   - Use `%i` somewhere in the ExecStart line

5. **journalctl query**: Run `journalctl -p err -b --no-pager | head -20` (errors since last boot) and save to `~/practice/journal_errors.txt`. Run `journalctl --disk-usage` and save to `~/practice/journal_disk.txt`.

## Hints

- `systemd-analyze` outputs "Startup finished in..." — if it says "not yet finished" the system is still booting (unlikely in a container, where systemd may not be PID 1)
- In a container without systemd as PID 1, `systemd-analyze` may fail — if so, write "container: no systemd" to the output files
- The `%i` specifier in a unit file is replaced with the instance name when starting `worker@primary.service`
