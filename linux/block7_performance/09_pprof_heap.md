# pprof, Heap Dumps, and Memory Profiling

Memory analysis has two layers: OS-level (what the kernel sees in `/proc`) and application-level (heap allocations inside a running process). Both are essential for diagnosing leaks and excessive memory use.

## /proc/PID/smaps — Detailed Memory Map

More detailed than `/proc/PID/maps` — shows RSS, PSS, and shared/private pages per mapping:

```bash
# Full smaps of the current shell
cat /proc/$$/smaps | head -60

# Sum private dirty memory (approximates actual RAM used)
grep Private_Dirty /proc/$$/smaps | awk '{sum+=$2} END{print sum/1024 "MB"}'

# Find the biggest memory regions
awk '/^[0-9a-f]/{name=$0} /^Size/{print $2, name}' /proc/$$/smaps | sort -rn | head -10
```

Key fields:
| Field | Meaning |
|-------|---------|
| `Rss` | Resident set: pages currently in RAM |
| `Pss` | Proportional set: RSS divided among all sharers |
| `Private_Clean` | Unmodified private pages (CoW not yet triggered) |
| `Private_Dirty` | Modified private pages — this is what you're actually using |
| `Shared_Dirty` | Shared pages you've written (rare) |

## gcore — Heap Dump of a Running Process

```bash
# Take a core dump of PID 1234 without killing it
sudo gcore -o /tmp/app.core 1234
# Produces /tmp/app.core.1234

# Analyze with gdb
gdb /usr/bin/myapp /tmp/app.core.1234
(gdb) info proc mappings
(gdb) info threads
(gdb) bt               # backtrace
```

`gcore` uses `ptrace` — the process pauses briefly during the dump.

## Go pprof — Application-Level Profiling

Go programs can expose runtime profiling over HTTP:

```go
import _ "net/http/pprof"
// Then: go tool pprof http://localhost:6060/debug/pprof/heap
```

### Profiles Available

```bash
# With a Go app running on :6060
go tool pprof http://localhost:6060/debug/pprof/heap      # heap allocations
go tool pprof http://localhost:6060/debug/pprof/profile   # 30s CPU profile
go tool pprof http://localhost:6060/debug/pprof/goroutine # all goroutines
go tool pprof http://localhost:6060/debug/pprof/allocs    # allocation counts
go tool pprof http://localhost:6060/debug/pprof/block     # blocking events
go tool pprof http://localhost:6060/debug/pprof/mutex     # mutex contention
```

### Analyzing pprof Profiles

```bash
# Interactive mode
go tool pprof profile.pb.gz
(pprof) top10           # top 10 by default metric
(pprof) top10 -cum      # cumulative (include callers)
(pprof) list funcname   # annotated source
(pprof) web             # open flame graph in browser

# Direct flame graph output
go tool pprof -http=:8888 profile.pb.gz

# One-shot text output
go tool pprof -top profile.pb.gz
```

### Capturing Profiles from CLI

```bash
# Heap: show live objects in memory
curl -s http://localhost:6060/debug/pprof/heap -o heap.pb.gz

# CPU: 30-second sample
curl -s "http://localhost:6060/debug/pprof/profile?seconds=30" -o cpu.pb.gz
```

## perf for Memory Analysis

```bash
# Cache misses (L1/L2/LLC)
perf stat -e cache-misses,cache-references,L1-dcache-load-misses ./program

# Memory access latency
perf mem record ./program
perf mem report

# Page faults (major = disk I/O required, minor = memory reuse)
perf stat -e major-faults,minor-faults ./program
```

## bpftrace for Allocation Tracing

```bash
# Count malloc calls by size
sudo bpftrace -e 'uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc { @sizes = hist(arg0); }'

# Trace large allocations (>1MB)
sudo bpftrace -e 'uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc /arg0 > 1048576/ { printf("large malloc: %d bytes by %s\n", arg0, comm); }'
```

## Detecting Leaks with /proc Monitoring

```bash
# Watch RSS growth of a process over time
PID=1234
while true; do
  grep VmRSS /proc/$PID/status
  sleep 5
done
```

## Valgrind (non-production, high overhead)

```bash
# Memory error detection
valgrind --leak-check=full --show-leak-kinds=all ./program

# Heap profiler
valgrind --tool=massif ./program
ms_print massif.out.* | head -40
```

## Further Reading

- [proc(5) smaps documentation](https://man7.org/linux/man-pages/man5/proc.5.html) — The canonical reference for every `/proc/PID/smaps` field (`Rss`, `Pss`, `Private_Dirty`, `Shared_Clean`) and the `/proc/PID/maps` virtual memory area format used in this lesson.
- [Go pprof documentation](https://pkg.go.dev/net/http/pprof) — The official Go pprof HTTP handler documentation covering heap, CPU, goroutine, allocs, block, and mutex profile endpoints and how to use `go tool pprof` to analyze them.
- [Brendan Gregg: Linux memory analysis](https://www.brendangregg.com/linuxperf.html#Memory) — Maps OS-level memory tools (`/proc/smaps`, `perf mem`, bpftrace malloc tracing) to the application-level pprof view, showing how both layers complement each other for leak diagnosis.
- [Valgrind manual: Massif heap profiler](https://valgrind.org/docs/manual/ms-manual.html) — Complete guide to `valgrind --tool=massif` heap profiling, including `ms_print` visualization and the snapshot format — the non-Go equivalent of pprof heap profiles.
