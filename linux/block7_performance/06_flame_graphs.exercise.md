# Flame Graphs — Exercises

Complete these tasks. The main deliverable is a documented workflow script.

## Task 1 — Write the flame graph generation workflow script

Create `~/practice/flamegraph_workflow.sh` that documents and (where possible) runs the full pipeline:

```bash
mkdir -p ~/practice
cat > ~/practice/flamegraph_workflow.sh << 'SCRIPT'
#!/bin/bash
# Flame Graph Generation Workflow
# Requires: perf, git, perl
# Container note: needs --privileged or perf_event_paranoid <= 1

set -e

WORKDIR="${1:-/tmp/flamegraph_work}"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "=== Step 1: Clone FlameGraph tools ==="
if [[ ! -d FlameGraph ]]; then
    git clone --depth 1 https://github.com/brendangregg/FlameGraph
fi

echo "=== Step 2: Record CPU profile (30 seconds, 99 Hz, all CPUs) ==="
# sudo perf record -g -F 99 -a -o perf.data sleep 30
echo "# Run: sudo perf record -g -F 99 -a -o perf.data sleep 30"

echo "=== Step 3: Convert perf.data to text with perf script ==="
# sudo perf script -i perf.data > out.perf
echo "# Run: sudo perf script -i perf.data > out.perf"
echo "# perf script produces one block per sample: PID/TID, timestamp, stack frames"

echo "=== Step 4: Collapse stacks with stackcollapse-perf.pl ==="
# ./FlameGraph/stackcollapse-perf.pl out.perf > out.folded
echo "# Run: ./FlameGraph/stackcollapse-perf.pl out.perf > out.folded"
echo "# Each output line: semicolon;delimited;stack N (where N = sample count)"

echo "=== Step 5: Render SVG flame graph ==="
# ./FlameGraph/flamegraph.pl out.folded > cpu.svg
echo "# Run: ./FlameGraph/flamegraph.pl out.folded > cpu.svg"
echo "# Output is an interactive SVG — open in browser"

echo "=== Step 6: (Optional) Diff two flame graphs ==="
# ./FlameGraph/difffolded.pl before.folded after.folded | ./FlameGraph/flamegraph.pl > diff.svg
echo "# Run: ./FlameGraph/difffolded.pl before.folded after.folded | ./FlameGraph/flamegraph.pl > diff.svg"

echo ""
echo "=== Alternative: py-spy for Python ==="
echo "# pip install py-spy"
echo "# py-spy record -o profile.svg -- python myscript.py"

echo ""
echo "=== How to read the output ==="
echo "# - Wide plateaus = hot functions (where CPU time is spent)"
echo "# - X-axis is alphabetical, NOT time order"
echo "# - Y-axis is stack depth (bottom = main/start, top = leaf)"
echo "# - Color is cosmetic (warm = on-CPU, cool = off-CPU by convention)"
SCRIPT
chmod +x ~/practice/flamegraph_workflow.sh
```

## Task 2 — Run the workflow script

```bash
bash ~/practice/flamegraph_workflow.sh
```

Review the output. It explains each step even if it cannot execute `perf` without privileges.

## Task 3 — Clone FlameGraph tools (if git is available)

```bash
if command -v git &>/dev/null; then
    git clone --depth 1 https://github.com/brendangregg/FlameGraph /tmp/FlameGraph 2>/dev/null || true
    ls /tmp/FlameGraph/*.pl 2>/dev/null | head -10
fi
```

## Task 4 — Verify the script

```bash
cat ~/practice/flamegraph_workflow.sh | grep "perf script"
```

You should see the `perf script` step documented in the file.

## Verification

```bash
ls -lh ~/practice/flamegraph_workflow.sh
bash ~/practice/flamegraph_workflow.sh | head -5
```
