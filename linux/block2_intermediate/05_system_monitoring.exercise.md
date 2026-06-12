# Exercise: System Monitoring

## Task 1 — Memory and uptime snapshot

Create `~/monitorlab/`. Capture system state:

1. Run `free -h` and save to `~/monitorlab/memory.txt`
2. Run `uptime` and save to `~/monitorlab/uptime.txt`
3. Run `cat /proc/loadavg` and save to `~/monitorlab/loadavg.txt`

## Task 2 — Disk usage

1. Run `df -h` and save to `~/monitorlab/disk_usage.txt`
2. Run `du -sh /etc /var /usr` (suppress permission errors with `2>/dev/null`) and save to `~/monitorlab/dir_sizes.txt`
3. Find the 5 largest files in `/usr/bin` using `du -ah /usr/bin | sort -rh | head -5` and save to `~/monitorlab/largest_binaries.txt`

## Task 3 — Process snapshot

1. Run `top -b -n 1` (batch mode, 1 iteration) and save to `~/monitorlab/top_snapshot.txt`
2. Extract just the process lines (skip the header) — lines after the empty line that follows the `%Cpu` line — and save to `~/monitorlab/process_list.txt`. You can use: `top -b -n 1 | tail -n +8`

## Task 4 — /proc inspection

1. Save the content of `/proc/meminfo` to `~/monitorlab/meminfo.txt`
2. Extract just the `MemTotal`, `MemFree`, and `MemAvailable` lines from it and save to `~/monitorlab/mem_summary.txt`
3. Save the content of `/proc/cpuinfo` to `~/monitorlab/cpuinfo.txt` and count how many `processor` entries there are (number of CPU threads), saving the count to `~/monitorlab/cpu_count.txt`
