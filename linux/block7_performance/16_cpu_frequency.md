# CPU Frequency Scaling and Power Management

Modern CPUs dynamically adjust their frequency based on load, thermal state, and power policy. This affects performance benchmarks, latency, and capacity planning. An SRE who doesn't account for frequency scaling will misinterpret performance data.

## The cpufreq Subsystem

Linux's cpufreq subsystem manages CPU frequency via a **governor** — a policy that decides when to scale up or down.

### Reading the Current State

```bash
# Current frequency for each CPU
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -8
# Output in kHz: 2400000 = 2.4 GHz

# Min and max allowed frequency
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null

# CPU's hardware min/max (the physical limits)
cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null
cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null

# Current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null

# Available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null
```

### Frequency Governors

| Governor | Behavior | When to Use |
|----------|---------|------------|
| `performance` | Always runs at max frequency | Latency-sensitive workloads, benchmarking |
| `powersave` | Always runs at min frequency | Battery-powered or cooling-constrained |
| `ondemand` | Scales up aggressively on load | General server workloads |
| `conservative` | Scales gradually | Slower response, smoother power |
| `schedutil` | Frequency tied to scheduler utilization | Default on modern kernels |

```bash
# View available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

# Set all CPUs to performance governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Restore to schedutil (or ondemand)
echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Using cpupower (if installed)
sudo cpupower frequency-info                        # detailed frequency info
sudo cpupower frequency-set -g performance          # set governor
sudo cpupower frequency-set -d 2GHz -u 3.5GHz      # set min/max
```

## Turbo Boost

Turbo Boost (Intel) / Precision Boost (AMD) allows CPUs to temporarily exceed their base clock when thermal and power headroom allows. A 2.4 GHz base clock may boost to 3.8 GHz on lightly-loaded cores.

```bash
# Check if turbo boost is enabled (Intel)
cat /sys/devices/system/cpu/intel_pstate/no_turbo
# 0 = turbo enabled (default)
# 1 = turbo disabled

# Disable turbo (reduces peak performance but improves consistency)
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Re-enable turbo
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# AMD turbo boost
cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
# 1 = enabled, 0 = disabled
```

### Why Disable Turbo?

Turbo introduces non-deterministic performance. A benchmark that boosts to 4GHz when cool runs differently at sustained load (2.4GHz). For latency-SLO workloads, consistent performance is more valuable than peak performance.

## C-States — CPU Sleep States

When idle, CPUs enter low-power sleep states (C-states). Deeper sleep states save more power but take longer to wake from:

| C-state | Wakeup latency | Power savings |
|---------|---------------|--------------|
| C0 | Active — no wait | None |
| C1 | 1–2 µs | Small |
| C2 | 10–20 µs | Moderate |
| C6 | 100–300 µs | High |

For latency-critical applications (< 100µs response time), deep C-states cause unexpected latency spikes.

```bash
# View C-state usage per CPU
ls /sys/devices/system/cpu/cpu0/cpuidle/
cat /sys/devices/system/cpu/cpu0/cpuidle/state*/name
cat /sys/devices/system/cpu/cpu0/cpuidle/state*/time   # microseconds spent in each state
cat /sys/devices/system/cpu/cpu0/cpuidle/state*/usage  # number of times entered

# Disable deep C-states (set max C-state to C1)
# Via kernel parameter: add to GRUB_CMDLINE_LINUX: intel_idle.max_cstate=1
# Or at runtime (less reliable):
cat /sys/devices/system/cpu/cpu0/cpuidle/state*/disable

# Using cpupower
sudo cpupower idle-info
sudo cpupower idle-set -D 2   # disable states deeper than C2
```

## /proc/cpuinfo — Observed Frequency

```bash
# Live observed frequency (not always accurate on all CPUs)
grep "cpu MHz" /proc/cpuinfo | head -8

# CPU flags relevant to power/frequency
grep flags /proc/cpuinfo | head -1 | tr ' ' '\n' | grep -E "est|acpi|epb|hfpme"
# est  = Enhanced Intel SpeedStep (frequency scaling)
# epb  = Energy Policy Bias (power preference control)
```

## Benchmarking and Frequency Scaling

```bash
# For reproducible benchmarks: disable turbo and set performance governor
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Verify all CPUs are at max frequency
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | sort -u

# After benchmarking: restore defaults
echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
```

## Further Reading

- [kernel.org: CPU frequency scaling](https://www.kernel.org/doc/html/latest/admin-guide/pm/cpufreq.html) — The authoritative kernel documentation for the cpufreq subsystem covering governor types (`schedutil`, `ondemand`, `performance`, `powersave`), the `intel_pstate` driver, and sysfs interface layout.
- [kernel.org: CPU idle management](https://www.kernel.org/doc/html/latest/admin-guide/pm/cpuidle.html) — Documents C-state management, the `intel_idle` driver, and how to disable deep sleep states to reduce wakeup latency for latency-sensitive workloads.
- [LWN: CPU frequency scaling](https://lwn.net/Articles/422397/) — LWN article covering the history of Linux frequency scaling governors, the design of `ondemand`, and the rationale for `schedutil` as the modern replacement.
- [Brendan Gregg: CPU utilization is wrong](https://www.brendangregg.com/blog/2017-05-09/cpu-utilization-is-wrong.html) — Explains how frequency scaling makes raw `%CPU` metrics misleading — a CPU at 50% utilization running at 2GHz does half the work of one at 50% running at 4GHz.
