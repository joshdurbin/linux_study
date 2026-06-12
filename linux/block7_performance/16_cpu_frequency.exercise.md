# Exercise: CPU Frequency Scaling

## Setup

```bash
mkdir -p ~/practice/cpufreq
sudo apt-get install -y linux-tools-common cpupower 2>/dev/null || \
    sudo apt-get install -y linux-tools-$(uname -r) 2>/dev/null || true
```

## Task 1: Read CPU Frequency Information

```bash
echo "=== CPU Frequency State ==="

# Current frequency
echo "Current frequency (kHz):"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -4 \
    || echo "cpufreq not available in this environment (normal in some containers)"

# Min/Max
echo ""
echo "Min/Max scaling frequency (kHz):"
for limit in scaling_min_freq scaling_max_freq; do
    echo -n "$limit: "
    cat /sys/devices/system/cpu/cpu0/cpufreq/$limit 2>/dev/null || echo "N/A"
done

# Hardware limits
echo ""
echo "Hardware min/max (kHz):"
cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null || echo "N/A"
cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo "N/A"
```

## Task 2: Check the Governor

```bash
echo "=== Governor ==="

# Current governor
echo "Current governor:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A"

# Available governors
echo "Available governors:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "N/A"

# /proc/cpuinfo MHz
echo ""
echo "Observed frequency from /proc/cpuinfo (MHz):"
grep "cpu MHz" /proc/cpuinfo | head -4
```

## Task 3: Check Turbo Boost Status

```bash
echo "=== Turbo Boost ==="

# Intel
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    VAL=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
    [ "$VAL" = "0" ] && echo "Intel turbo boost: ENABLED" || echo "Intel turbo boost: DISABLED"
fi

# AMD
if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
    VAL=$(cat /sys/devices/system/cpu/cpufreq/boost)
    [ "$VAL" = "1" ] && echo "AMD boost: ENABLED" || echo "AMD boost: DISABLED"
fi

# Generic check
ls /sys/devices/system/cpu/intel_pstate/ 2>/dev/null
```

## Task 4: Inspect C-States

```bash
echo "=== C-State Information ==="

if [ -d /sys/devices/system/cpu/cpu0/cpuidle ]; then
    echo "Available C-states for cpu0:"
    for state in /sys/devices/system/cpu/cpu0/cpuidle/state*/; do
        name=$(cat $state/name 2>/dev/null)
        time=$(cat $state/time 2>/dev/null)
        usage=$(cat $state/usage 2>/dev/null)
        echo "  $name: entered=${usage} times, total=${time}µs"
    done
else
    echo "cpuidle not available in this environment"
fi
```

## Task 5: Attempt Governor Change

```bash
CURRENT_GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
if [ -n "$CURRENT_GOV" ]; then
    echo "Current governor: $CURRENT_GOV"

    # Try setting performance governor
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
    echo "Set to: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"

    # Restore
    echo "$CURRENT_GOV" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
    echo "Restored to: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
else
    echo "cpufreq governor control not available in this environment"
fi
```

## Task 6: Write a CPU Power Summary Script

```bash
cat > ~/practice/cpufreq/cpu_power_summary.sh << 'EOF'
#!/bin/bash
echo "=== CPU Power/Frequency Summary ==="

# Number of CPUs
CPUS=$(nproc)
echo "Logical CPUs: $CPUS"

# Frequency info
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
    MIN=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)
    MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)
    CUR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    echo "Governor: $GOV"
    echo "Frequency: ${CUR}kHz (min=${MIN}kHz, max=${MAX}kHz)"
else
    echo "Frequency from /proc/cpuinfo:"
    grep "cpu MHz" /proc/cpuinfo | awk '{sum+=$4; count++} END {printf "  avg: %.0f MHz\n", sum/count}'
fi

# Turbo
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
    NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
    [ "$NO_TURBO" = "0" ] && echo "Turbo boost: enabled" || echo "Turbo boost: disabled"
fi

# C-states summary
if [ -d /sys/devices/system/cpu/cpu0/cpuidle ]; then
    DEEPEST=$(ls /sys/devices/system/cpu/cpu0/cpuidle/ | tail -1)
    DEEPEST_NAME=$(cat /sys/devices/system/cpu/cpu0/cpuidle/$DEEPEST/name 2>/dev/null)
    echo "Deepest C-state available: $DEEPEST_NAME"
fi
EOF
chmod +x ~/practice/cpufreq/cpu_power_summary.sh
bash ~/practice/cpufreq/cpu_power_summary.sh
```

## Expected Outcome

- `/sys/devices/system/cpu/cpu0/cpufreq/` directory is accessible (or graceful fallback)
- `scaling_governor` reports the current governor
- `scaling_available_governors` lists available choices
- `/proc/cpuinfo` shows `cpu MHz` values
- Turbo boost status is readable from Intel or AMD sysfs path
- `~/practice/cpufreq/cpu_power_summary.sh` reports governor, frequency, and turbo status
