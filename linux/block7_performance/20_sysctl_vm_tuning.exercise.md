# sysctl VM Tuning Exercises

These exercises focus on reading and understanding VM tuning parameters, writing tuning profiles, and monitoring swap/page fault activity via `/proc/vmstat`. Writes to sysctl may require privileges available in the container.

## Setup

```bash
mkdir -p ~/practice/sysctl_vm
cd ~/practice/sysctl_vm
```

---

## Task 1: Read All VM-Related sysctl Parameters

Dump all `vm.*` sysctl parameters to a file for reference.

```bash
sysctl -a 2>/dev/null | grep '^vm\.' | tee ~/practice/sysctl_vm/vm_params.txt
wc -l ~/practice/sysctl_vm/vm_params.txt
```

How many `vm.*` parameters does your kernel expose? Note which ones match the lesson content.

Also read the full kernel parameter list to see the scope:
```bash
sysctl -a 2>/dev/null | grep -E '^(vm|kernel|fs)\.' | wc -l
```

---

## Task 2: Understand Current vm.swappiness

Read the current `vm.swappiness` value and check for swap usage:

```bash
# Read the parameter
sysctl vm.swappiness

# Check if swap is configured
cat /proc/meminfo | grep -i swap

# Read the /proc/sys path directly (equivalent to sysctl)
cat /proc/sys/vm/swappiness
```

Now read the other memory-related sysctl settings in one command:
```bash
sysctl vm.swappiness \
       vm.dirty_ratio \
       vm.dirty_background_ratio \
       vm.dirty_expire_centisecs \
       vm.dirty_writeback_centisecs \
       vm.vfs_cache_pressure \
       vm.min_free_kbytes 2>/dev/null
```

Save these defaults to a file:
```bash
sysctl vm.swappiness \
       vm.dirty_ratio \
       vm.dirty_background_ratio \
       vm.dirty_expire_centisecs \
       vm.dirty_writeback_centisecs \
       vm.vfs_cache_pressure \
       vm.min_free_kbytes 2>/dev/null \
  > ~/practice/sysctl_vm/current_defaults.txt
cat ~/practice/sysctl_vm/current_defaults.txt
```

---

## Task 3: Read /proc/vmstat for Swap Activity

`/proc/vmstat` is the kernel's running VM event counter. Read it and find the swap-in and swap-out counters:

```bash
# Show all vmstat entries
cat /proc/vmstat

# Filter to just the swap and page fault lines
grep -E 'pswpin|pswpout|pgfault|pgmajfault|nr_dirty|nr_writeback' /proc/vmstat
```

Capture the fields of interest with `awk`:
```bash
awk '/^pswpin|^pswpout|^pgfault|^pgmajfault|^nr_dirty|^nr_writeback/' /proc/vmstat
```

If `pswpin` and `pswpout` are 0 (or there's no swap configured), that's normal in a container — swap is often disabled.

Observe the dirty/writeback page counts — they reflect activity from the running container filesystem writes.

---

## Task 4: Temporarily Tune vm.dirty_ratio and Verify

Try setting `vm.dirty_ratio` to a different value and verify the change takes effect. In a privileged container this should work:

```bash
# Read current value
sysctl vm.dirty_ratio

# Attempt to change it
sysctl -w vm.dirty_ratio=25 2>&1 || echo "(write requires root/privilege)"

# Verify
sysctl vm.dirty_ratio

# Also try the /proc path
echo 25 | tee /proc/sys/vm/dirty_ratio 2>&1 || echo "(write requires privilege)"
```

Even if writes fail in your container environment, understanding the mechanism is the goal. Note what error you get and why.

---

## Task 5: Write a VM Tuning Profile for a Database Workload

Create a sysctl configuration file representing a database server tuning profile:

```bash
cat > ~/practice/sysctl_vm/db_tuning.conf <<'EOF'
# VM tuning profile for PostgreSQL / MySQL database server
# Apply with: sysctl -p /etc/sysctl.d/99-database.conf

# Keep working set (buffer pool) in RAM, avoid swap
vm.swappiness = 1

# Low dirty ratios to prevent write stall spikes on checkpoint
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2

# More frequent writeback to keep dirty page accumulation bounded
vm.dirty_expire_centisecs = 1000
vm.dirty_writeback_centisecs = 100

# Keep inode/dentry cache — databases open many files
vm.vfs_cache_pressure = 50

# Reserve 1GB free to prevent OOM surprises
vm.min_free_kbytes = 1048576

# Container environments spawn many processes
kernel.pid_max = 4194304

# Databases open many connection FDs
fs.file-max = 2097152
EOF
```

Annotate each parameter — add a comment after the value explaining what it does and the tradeoff. Then verify the file is valid by checking it can be parsed:
```bash
cat ~/practice/sysctl_vm/db_tuning.conf
# If you have sysctl access, dry-run it:
sysctl -p ~/practice/sysctl_vm/db_tuning.conf --dry-run 2>&1 | head -20 || true
```

---

## Task 6: Write a /proc/vmstat Monitoring Script

Create `~/practice/sysctl_vm/vmstat_watch.sh` that reads `/proc/vmstat` at intervals and reports the *rate* of swap activity and page faults (delta per second):

```bash
#!/bin/bash
# vmstat_watch.sh — monitor swap and page fault rates from /proc/vmstat
# Usage: ./vmstat_watch.sh [interval_seconds]

INTERVAL="${1:-2}"

get_field() {
    awk -v field="$1" '$1 == field {print $2}' /proc/vmstat
}

prev_pswpin=$(get_field pswpin)
prev_pswpout=$(get_field pswpout)
prev_pgfault=$(get_field pgfault)
prev_pgmajfault=$(get_field pgmajfault)
prev_ts=$(date +%s%N)

echo "Monitoring /proc/vmstat (interval: ${INTERVAL}s). Ctrl-C to stop."
echo "---"
printf "%-20s %10s %10s %12s %12s\n" "Timestamp" "SwapIn/s" "SwapOut/s" "MinFaults/s" "MajFaults/s"
echo "--------------------------------------------------------------------"

while true; do
    sleep "$INTERVAL"

    curr_pswpin=$(get_field pswpin)
    curr_pswpout=$(get_field pswpout)
    curr_pgfault=$(get_field pgfault)
    curr_pgmajfault=$(get_field pgmajfault)
    curr_ts=$(date +%s%N)

    elapsed_ms=$(( (curr_ts - prev_ts) / 1000000 ))
    # Avoid division by zero
    [[ $elapsed_ms -lt 1 ]] && elapsed_ms=1

    swap_in_rate=$(awk "BEGIN {printf \"%.1f\", ($curr_pswpin - $prev_pswpin) * 1000 / $elapsed_ms}")
    swap_out_rate=$(awk "BEGIN {printf \"%.1f\", ($curr_pswpout - $prev_pswpout) * 1000 / $elapsed_ms}")
    min_fault_rate=$(awk "BEGIN {printf \"%.0f\", ($curr_pgfault - $prev_pgfault) * 1000 / $elapsed_ms}")
    maj_fault_rate=$(awk "BEGIN {printf \"%.1f\", ($curr_pgmajfault - $prev_pgmajfault) * 1000 / $elapsed_ms}")

    printf "%-20s %10s %10s %12s %12s\n" \
        "$(date '+%H:%M:%S')" \
        "${swap_in_rate}" \
        "${swap_out_rate}" \
        "${min_fault_rate}" \
        "${maj_fault_rate}"

    # Also report current dirty/writeback page count
    dirty=$(get_field nr_dirty)
    writeback=$(get_field nr_writeback)
    echo "  [nr_dirty=${dirty} pages, nr_writeback=${writeback} pages]"

    prev_pswpin=$curr_pswpin
    prev_pswpout=$curr_pswpout
    prev_pgfault=$curr_pgfault
    prev_pgmajfault=$curr_pgmajfault
    prev_ts=$curr_ts
done
```

Make it executable and run it briefly:
```bash
chmod +x ~/practice/sysctl_vm/vmstat_watch.sh
timeout 6 ~/practice/sysctl_vm/vmstat_watch.sh 2 || true
```

---

## Reflection Questions

1. What is the difference between `vm.dirty_ratio` and `vm.dirty_background_ratio`? Which one causes application stalls?
2. Why would you set `vm.swappiness=1` rather than `vm.swappiness=0` on a database server?
3. What does a high `pgmajfault` rate in `/proc/vmstat` indicate about a workload?
4. Why are percentage-based dirty limits (`dirty_ratio`) potentially dangerous on systems with very large RAM?
5. In a Docker container, why might `sysctl -w vm.swappiness=1` fail even as root?
