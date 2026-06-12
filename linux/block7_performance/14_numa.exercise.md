# Exercise: NUMA

## Setup

```bash
mkdir -p ~/practice/numa
sudo apt-get install -y numactl 2>/dev/null || true
```

## Task 1: Discover the NUMA Topology

```bash
# How many NUMA nodes?
ls /sys/devices/system/node/ | grep "node[0-9]"

# For each node, show its CPUs
for node in /sys/devices/system/node/node*/; do
    echo "$(basename $node): CPUs $(cat $node/cpulist 2>/dev/null)"
done

# numactl hardware summary
numactl --hardware 2>/dev/null || echo "numactl not available — checking via /sys"

# lscpu NUMA info
lscpu | grep -iE "numa|socket|node"
```

## Task 2: Read Per-Node Memory Info

```bash
for node in /sys/devices/system/node/node*/; do
    echo "=== $(basename $node) ==="
    grep -E "MemTotal|MemFree|MemUsed" $node/meminfo 2>/dev/null | head -3
done
```

## Task 3: View numastat

```bash
numastat 2>/dev/null || echo "numastat not available"

# Parse raw NUMA stats from /proc
awk '
/numa_hit/ {print "node", NR-1, "numa_hit:", $2}
/numa_miss/ {print "node", NR-1, "numa_miss:", $2}
' /sys/devices/system/node/node*/numastat 2>/dev/null | head -20 || \
    cat /sys/devices/system/node/node0/numastat 2>/dev/null
```

## Task 4: Run a Process with NUMA Policy

```bash
# Run on node 0 CPUs only with memory from node 0
numactl --cpunodebind=0 --membind=0 bash -c 'echo "Running on node 0"' 2>/dev/null || \
    echo "numactl not available (may be in a VM/container with single NUMA node)"

# Check the NUMA policy of the current process
cat /proc/self/numa_maps | head -10 2>/dev/null || echo "numa_maps not available"
```

## Task 5: Check NUMA Balancing

```bash
echo "NUMA auto-balancing: $(sysctl -n kernel.numa_balancing 2>/dev/null || echo 'N/A')"
echo "  1 = kernel auto-migrates memory toward the CPU using it"
echo "  0 = disabled (manually place processes instead)"
```

## Task 6: Find CPU-to-Node Mapping

```bash
# For each logical CPU, show its NUMA node
echo "CPU to NUMA node mapping:"
for cpu in /sys/devices/system/cpu/cpu[0-9]*/; do
    cpu_num=$(basename $cpu | tr -d 'cpu')
    pkg=$(cat $cpu/topology/physical_package_id 2>/dev/null)
    node=$(cat /sys/devices/system/cpu/cpu${cpu_num}/node* 2>/dev/null | head -1 | grep -oE 'node[0-9]+')
    echo "  cpu${cpu_num} → socket $pkg / $node"
done | head -20
```

## Task 7: Write a NUMA Summary Script

```bash
cat > ~/practice/numa/numa_summary.sh << 'EOF'
#!/bin/bash
echo "=== NUMA Summary ==="

NODES=$(ls /sys/devices/system/node/ 2>/dev/null | grep -c "^node[0-9]")
echo "NUMA nodes: $NODES"

if [ "$NODES" -le 1 ]; then
    echo "Single NUMA node (UMA-like topology)"
fi

for node in /sys/devices/system/node/node*/; do
    n=$(basename $node)
    cpus=$(cat $node/cpulist 2>/dev/null)
    total=$(awk '/MemTotal/{print $2}' $node/meminfo 2>/dev/null)
    free=$(awk '/MemFree/{print $2}' $node/meminfo 2>/dev/null)
    echo "$n: CPUs=[$cpus] Memory=${total}kB total, ${free}kB free"
done

echo ""
echo "NUMA balancing: $(sysctl -n kernel.numa_balancing 2>/dev/null)"

if command -v numactl > /dev/null 2>&1; then
    echo ""
    numactl --hardware 2>/dev/null
fi
EOF
chmod +x ~/practice/numa/numa_summary.sh
bash ~/practice/numa/numa_summary.sh
```

## Expected Outcome

- `/sys/devices/system/node/` lists available NUMA nodes
- Per-node CPU list and memory info are readable
- `numactl --hardware` shows node distances (if numactl is installed)
- `kernel.numa_balancing` sysctl is readable
- `~/practice/numa/numa_summary.sh` reports topology and memory per node
