# Flame Graphs

## What Flame Graphs Show

A flame graph is a visualization of stack traces sampled from a running program. Each rectangle is a stack frame; the width represents the proportion of total samples where that frame appeared. The y-axis is stack depth (bottom = first frame, top = deepest).

Key properties:
- **X-axis is alphabetical**, not chronological. The horizontal position within a row is meaningless for time ordering.
- **Width = time**. A wide box means that function (and everything it called) was on-CPU for a large fraction of samples.
- **Color is arbitrary**. Gregg uses warm colors for CPU flame graphs, cool colors for off-CPU — but this is cosmetic.
- **Plateaus are hot paths**. A wide flat top means a function was on-CPU with no children — the actual work is happening there.

## Three Types of Flame Graphs

| Type | What it answers |
|------|----------------|
| CPU (on-CPU) | Where is the CPU spending time? |
| Off-CPU | Where is the application waiting (I/O, locks, sleep)? |
| Memory allocation | Which code paths allocate the most memory? |

For CPU flame graphs, samples are taken while the CPU is running (on-CPU). Off-CPU flame graphs trace the time between going off-CPU (e.g., blocking on a read) and returning on-CPU.

## Generating a CPU Flame Graph with perf

> **Note:** Requires a privileged container or `perf_event_paranoid <= 1` and the FlameGraph repo.

```bash
# 1. Record call graphs at 99 Hz for 30 seconds
sudo perf record -g -F 99 -a sleep 30

# 2. Convert perf.data to text format
sudo perf script > out.perf

# 3. Collapse stacks (from FlameGraph repo)
git clone https://github.com/brendangregg/FlameGraph
./FlameGraph/stackcollapse-perf.pl out.perf > out.folded

# 4. Render SVG
./FlameGraph/flamegraph.pl out.folded > cpu_flamegraph.svg

# 5. View in browser
xdg-open cpu_flamegraph.svg   # or copy to a web server
```

## The stackcollapse → flamegraph Pipeline

`stackcollapse-perf.pl` converts `perf script` output (one line per sample, with stack frames) into the "folded" format: each line is a semicolon-separated stack followed by a space and a count:

```
bash;readline;rl_complete;rl_completion_matches 42
bash;execute_command;execute_simple_command 158
```

`flamegraph.pl` reads folded format and emits an SVG with interactive hover.

## Stackcollapse Scripts for Other Profilers

The FlameGraph repo includes collapse scripts for:
- `stackcollapse-perf.pl` — Linux `perf script` output
- `stackcollapse.pl` — DTrace output
- `stackcollapse-jstack.pl` — Java thread dumps
- `stackcollapse-gdb.pl` — GDB backtraces

## Alternative Profilers

**Python:** `py-spy` generates flame graphs with zero code changes:
```bash
pip install py-spy
py-spy record -o profile.svg -- python myscript.py
```

**JVM:** `async-profiler` (low-overhead Java profiler):
```bash
./profiler.sh -d 30 -f flamegraph.html <PID>
```

**Go:** built-in pprof:
```bash
go tool pprof -http=:8080 cpu.pprof
```

## Reading a Flame Graph Checklist

1. Find the widest plateaus — these are the hot functions
2. Look for tower shapes (deep call stacks with narrow tops) — may indicate excessive recursion or framework overhead
3. Look for unexpected functions in hot paths (serialization, GC, logging)
4. Compare two flame graphs with `difffolded.pl` to find regressions:

```bash
./FlameGraph/difffolded.pl before.folded after.folded | ./FlameGraph/flamegraph.pl > diff.svg
```

## Further Reading

- [Brendan Gregg: Flame Graphs](https://www.brendangregg.com/flamegraphs.html) — The canonical source for flame graph methodology, covering CPU, off-CPU, memory, and differential flame graphs with tool-specific instructions for perf, BCC, and DTrace.
- [FlameGraph GitHub repository](https://github.com/brendangregg/FlameGraph) — The source for `flamegraph.pl` and all `stackcollapse-*.pl` scripts; the `examples/` directory contains real folded-stack samples demonstrating CPU, off-CPU, and allocation flame graph patterns.
- [ACM Queue: The Flame Graph](https://queue.acm.org/detail.cfm?id=2927301) — Brendan Gregg's peer-reviewed article explaining the visualization design decisions (x-axis alphabetical, width = time) and how to correctly read plateaus vs towers.
- [Julia Evans: How do Ruby and Python profilers work?](https://jvns.ca/blog/2017/12/17/how-do-ruby---python-profilers-work-/) — Explains sampling vs instrumentation profiling and why sample-based profilers (which produce flame graph input) have much lower overhead than tracing profilers.
