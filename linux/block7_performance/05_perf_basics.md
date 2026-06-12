# perf Basics

## Privilege Requirements

`perf` reads hardware performance counters and kernel symbols. It requires either:
- `sudo` or `CAP_PERFMON` capability
- Kernel setting: `echo 1 > /proc/sys/kernel/perf_event_paranoid`

Default `perf_event_paranoid=2` (or higher on hardened systems) restricts access. In containers, `perf` typically needs a **privileged container** or the `--cap-add SYS_ADMIN` flag.

Check current setting:
```bash
cat /proc/sys/kernel/perf_event_paranoid
# -1 = unrestricted, 0 = allow kernel data, 1 = allow user data, 2+ = restricted
```

To temporarily allow access (as root):
```bash
echo 1 | sudo tee /proc/sys/kernel/perf_event_paranoid
```

## perf stat — Hardware Counter Summary

`perf stat` runs a command and reports hardware event counts when it exits:

```bash
perf stat ls /tmp
perf stat -a sleep 5    # system-wide for 5 seconds
perf stat -p 1234       # attach to running process
```

Key metrics:

| Metric | Meaning |
|--------|---------|
| `cycles` | CPU clock cycles consumed |
| `instructions` | Machine instructions retired |
| `IPC` | Instructions per cycle — efficiency (>1 = good, <0.5 = stalled) |
| `cache-misses` | L1/L2/L3 cache misses |
| `branch-misses` | Mispredicted branches (pipeline flushes) |
| `task-clock` | CPU time in ms |

Low IPC with high cache misses = memory-bound workload. Low IPC with high branch misses = branch-prediction-limited code.

## perf record — Sampling Profiler

`perf record` samples the CPU at a set frequency (default 4000 Hz) and saves to `perf.data`:

```bash
perf record -g ls /tmp           # with call graph
perf record -g -F 99 -a sleep 10 # system-wide, 99 Hz, 10 seconds
perf record -g -p 1234           # attach to process
```

`-g` enables call graph capture (stack traces). Use `-F 99` instead of `-F 100` to avoid lockstep with 100 Hz timer interrupts.

Output file `perf.data` is created in the current directory.

## perf report — Interactive TUI

```bash
perf report          # open perf.data in TUI
perf report --stdio  # text output
```

The TUI shows a call tree sorted by `%` of samples. Press `Enter` to expand, `a` to annotate (shows assembly). Navigate with arrow keys, `q` to quit.

## perf list — Available Events

```bash
perf list            # all available events
perf list | grep cache   # filter
perf list tracepoint     # kernel tracepoints
```

Events fall into categories: hardware (CPU counters), software (kernel counters), tracepoints (kernel event hooks), hardware cache events, and PMU-specific events.

## Alternatives When perf is Unavailable

When running in a restricted container without `perf`:

**Per-process scheduling stats:**
```bash
cat /proc/$(pgrep myapp)/schedstat
# fields: runtime (ns), wait time (ns), timeslices
```

**Kernel tracing via debugfs:**
```bash
ls /sys/kernel/debug/tracing/     # if mounted
cat /sys/kernel/debug/tracing/available_tracers
```

**CPU cycle estimation via /proc/stat:**
```bash
awk '/^cpu / {print "user="$2, "nice="$3, "sys="$4, "idle="$5}' /proc/stat
```

**Software-only profiling:**
```bash
# gprof (compile-time instrumentation)
gcc -pg -o myapp myapp.c
./myapp
gprof myapp gmon.out | head -30
```

## perf Workflow Summary

```bash
# 1. Record
sudo perf record -g -F 99 ./myapp

# 2. Report (TUI)
sudo perf report

# 3. Or generate text flamegraph input
sudo perf script > out.perf
# Then process with FlameGraph tools (see flame_graphs lesson)
```

## Further Reading

- [perf wiki](https://perf.wiki.kernel.org/index.php/Main_Page) — The official perf documentation covering all subcommands (`stat`, `record`, `report`, `top`, `script`, `list`), event types, and the `perf_event_paranoid` permission model.
- [perf_event_open(2) man page](https://man7.org/linux/man-pages/man2/perf_event_open.2.html) — Documents the kernel syscall underlying all perf functionality, including the `perf_event_attr` struct fields that control sampling frequency, hardware counters, and the paranoia level.
- [Brendan Gregg: perf examples](https://www.brendangregg.com/perf.html) — Extensive collection of real-world `perf stat`, `perf record`, and `perf script` one-liners covering CPU profiling, cache analysis, and flame graph generation.
- [LWN: The perf performance counters subsystem](https://lwn.net/Articles/339361/) — The original LWN article introducing the perf events subsystem, covering hardware counter access, software events, and the design goals behind `perf_event_paranoid`.
