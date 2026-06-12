# Exercise: Pressure Stall Information (PSI)

## Setup

```bash
mkdir -p ~/practice/psi
```

## Task 1: Read Raw PSI Files

```bash
# CPU pressure
echo "=== CPU ==="
cat /proc/pressure/cpu

# Memory pressure
echo "=== Memory ==="
cat /proc/pressure/memory

# I/O pressure
echo "=== I/O ==="
cat /proc/pressure/io
```

Note which resources show non-zero `avg10` values.

## Task 2: Extract avg10 Values with awk

```bash
# Extract the 10-second average 'some' stall for each resource
for res in cpu memory io; do
    avg10=$(awk '/^some/ {
        for (i=1; i<=NF; i++) {
            if ($i ~ /^avg10=/) { split($i, a, "="); print a[2] }
        }
    }' /proc/pressure/$res)
    echo "$res some avg10: $avg10%"
done
```

## Task 3: Compute Stall Rate Over an Interval

Use the `total` field (microseconds) to measure actual stall time over a 5-second window:

```bash
before_cpu=$(awk '/^some/ {print $NF}' /proc/pressure/cpu | cut -d= -f2)
before_io=$(awk '/^some/ {print $NF}' /proc/pressure/io | cut -d= -f2)

sleep 5

after_cpu=$(awk '/^some/ {print $NF}' /proc/pressure/cpu | cut -d= -f2)
after_io=$(awk '/^some/ {print $NF}' /proc/pressure/io | cut -d= -f2)

echo "CPU stall in 5s: $(( (after_cpu - before_cpu) / 1000 )) ms"
echo "I/O stall in 5s: $(( (after_io - before_io) / 1000 )) ms"
```

## Task 4: Write a PSI Health Check Script

```bash
cat > ~/practice/psi/psi_check.sh << 'EOF'
#!/bin/bash
WARN=0

check_pressure() {
    local res=$1
    local threshold=${2:-10}

    local val=$(awk '/^some/ {
        for (i=1; i<=NF; i++) {
            if ($i ~ /^avg60=/) { split($i, a, "="); print a[2] }
        }
    }' /proc/pressure/$res)

    echo "$res some avg60: ${val}%"

    awk -v val="$val" -v res="$res" -v thresh="$threshold" 'BEGIN {
        if (val+0 > thresh+0) {
            print "  WARNING: "res" pressure above "thresh"%"
            exit 1
        }
    }' && return 0 || { WARN=1; return 1; }
}

check_pressure cpu    10
check_pressure memory  1
check_pressure io     10

# Also check 'full' for memory and io
for res in memory io; do
    full=$(awk '/^full/ {
        for (i=1; i<=NF; i++) {
            if ($i ~ /^avg60=/) { split($i, a, "="); print a[2] }
        }
    }' /proc/pressure/$res)
    echo "$res full avg60: ${full}%"
    awk -v val="$full" -v res="$res" 'BEGIN {
        if (val+0 > 1) print "  WARNING: "res" full stall above 1%"
    }'
done

[ $WARN -eq 0 ] && echo "All resources OK" || echo "Pressure warnings detected"
EOF
chmod +x ~/practice/psi/psi_check.sh
bash ~/practice/psi/psi_check.sh
```

## Task 5: Explore per-cgroup PSI (if cgroups v2 is mounted)

```bash
# Check if cgroups v2 is mounted
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo "cgroups v2 is active"
    # Show CPU pressure for the root cgroup (if supported by kernel)
    ls /sys/fs/cgroup/*.pressure 2>/dev/null || echo "pressure files not in root cgroup"
else
    echo "cgroups v1 or hybrid — per-cgroup PSI requires v2"
fi
```

## Expected Outcome

- `/proc/pressure/cpu`, `/proc/pressure/memory`, `/proc/pressure/io` are all readable
- `awk` can extract `avg10` values from PSI files
- `~/practice/psi/psi_check.sh` reads `avg60` for all three resources and warns if above threshold
- You can compute per-interval stall time using the `total` microsecond counter
