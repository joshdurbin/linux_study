# eBPF Introduction — Exercises

> **Container note:** Full eBPF usage requires a privileged container. If unavailable, complete the documentation tasks — they are equally important for understanding the technology.

Complete these tasks. Record findings in `~/practice/ebpf_intro.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Check eBPF/bpftrace availability

```bash
echo "=== eBPF tool availability ===" >> ~/practice/ebpf_intro.txt
echo "--- bpftrace ---" >> ~/practice/ebpf_intro.txt
which bpftrace >> ~/practice/ebpf_intro.txt 2>&1 || echo "bpftrace not installed" >> ~/practice/ebpf_intro.txt
bpftrace --version >> ~/practice/ebpf_intro.txt 2>&1 || true

echo "--- BCC tools ---" >> ~/practice/ebpf_intro.txt
which opensnoop >> ~/practice/ebpf_intro.txt 2>&1 || \
    ls /usr/share/bcc/tools/ 2>/dev/null | head -5 >> ~/practice/ebpf_intro.txt || \
    echo "BCC tools not installed" >> ~/practice/ebpf_intro.txt
```

## Task 2 — Check BTF support

```bash
echo "=== BTF (CO-RE) support ===" >> ~/practice/ebpf_intro.txt
if [[ -f /sys/kernel/btf/vmlinux ]]; then
    echo "BTF available: /sys/kernel/btf/vmlinux exists" >> ~/practice/ebpf_intro.txt
    ls -lh /sys/kernel/btf/vmlinux >> ~/practice/ebpf_intro.txt
else
    echo "BTF vmlinux not found at /sys/kernel/btf/vmlinux" >> ~/practice/ebpf_intro.txt
fi

echo "--- kernel config ---" >> ~/practice/ebpf_intro.txt
zcat /proc/config.gz 2>/dev/null | grep -E 'CONFIG_(BPF|DEBUG_INFO_BTF)' >> ~/practice/ebpf_intro.txt \
    || grep -E 'CONFIG_(BPF|DEBUG_INFO_BTF)' /boot/config-$(uname -r) 2>/dev/null >> ~/practice/ebpf_intro.txt \
    || echo "kernel config not accessible" >> ~/practice/ebpf_intro.txt
```

## Task 3 — List bpftrace tracepoints (if available)

```bash
echo "=== syscall tracepoints ===" >> ~/practice/ebpf_intro.txt
if command -v bpftrace &>/dev/null; then
    bpftrace -l 'tracepoint:syscalls:*' 2>/dev/null | head -20 >> ~/practice/ebpf_intro.txt
else
    echo "bpftrace unavailable — listing via /sys/kernel/debug/tracing:" >> ~/practice/ebpf_intro.txt
    ls /sys/kernel/debug/tracing/events/syscalls/ 2>/dev/null | head -20 >> ~/practice/ebpf_intro.txt \
        || echo "debugfs also not available" >> ~/practice/ebpf_intro.txt
fi
```

## Task 4 — Document eBPF concepts

Add a structured summary of eBPF to your notes:

```bash
cat >> ~/practice/ebpf_intro.txt << 'EOF'

=== eBPF Concepts Summary ===

PROBE TYPES:
  kprobe      - kernel function entry (dynamic, may break between kernel versions)
  kretprobe   - kernel function return
  tracepoint  - stable kernel hooks (preferred - stable ABI)
  uprobe      - user-space function entry
  uretprobe   - user-space function return
  XDP         - eXpress Data Path (network, pre-stack)

MAP TYPES:
  BPF_MAP_TYPE_HASH       - key/value lookup
  BPF_MAP_TYPE_ARRAY      - index-based, pre-allocated
  BPF_MAP_TYPE_PERCPU_*   - per-CPU variants (no atomic ops needed)
  BPF_MAP_TYPE_RINGBUF    - efficient event ring buffer (Linux 5.8+)
  BPF_MAP_TYPE_STACK_TRACE - stack trace storage for flame graphs

SAFETY GUARANTEES:
  - Verifier proves program terminates (no unbounded loops)
  - Verifier proves no invalid memory access
  - Programs run in kernel context but cannot crash the kernel
  - JIT-compiled to native code for near-zero overhead

TOOLCHAIN:
  bpftrace  - high-level scripting (one-liners to full scripts)
  BCC       - Python + C, runtime compilation (needs kernel headers)
  libbpf    - C library with CO-RE (portable, production use)
EOF
```

## Task 5 — Kernel version check

```bash
echo "=== kernel version ===" >> ~/practice/ebpf_intro.txt
uname -r >> ~/practice/ebpf_intro.txt
echo "# eBPF feature availability by version:" >> ~/practice/ebpf_intro.txt
echo "# 4.4+  basic eBPF maps and programs" >> ~/practice/ebpf_intro.txt
echo "# 4.7+  tracepoints" >> ~/practice/ebpf_intro.txt
echo "# 4.9+  kprobe on all functions" >> ~/practice/ebpf_intro.txt
echo "# 5.2+  BTF type info in kernel" >> ~/practice/ebpf_intro.txt
echo "# 5.8+  ring buffer map" >> ~/practice/ebpf_intro.txt
```

## Verification

```bash
cat ~/practice/ebpf_intro.txt
```
