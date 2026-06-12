# eBPF Introduction

## What eBPF Is

eBPF (Extended Berkeley Packet Filter) allows you to run sandboxed programs in the Linux kernel without changing kernel source code or loading kernel modules. Programs are attached to kernel hooks and execute when those hooks fire — with microsecond overhead rather than the milliseconds of context-switching overhead from user-space polling.

Classic BPF (cBPF) was limited to network packet filtering (used by `tcpdump`). eBPF extended this to a general-purpose kernel instrumentation platform with a 64-bit register-based VM, maps for data storage, and dozens of program types.

> **Container note:** eBPF requires either a privileged container (`--privileged`) or specific capabilities (`CAP_BPF`, `CAP_SYS_ADMIN`, `CAP_PERFMON`). Most standard containers do not have access.

## How eBPF Programs Work

1. **Write**: eBPF program in restricted C (or higher-level language like bpftrace)
2. **Compile**: LLVM/Clang compiles to eBPF bytecode
3. **Verify**: Kernel verifier checks safety — no unbounded loops, no invalid memory access, bounded stack
4. **JIT**: Kernel JIT-compiles bytecode to native machine code
5. **Attach**: Program attached to a hook point
6. **Run**: Executes in-kernel on each event, writes data to maps
7. **Read**: User-space reads results from maps

The verifier is the key safety guarantee — it statically proves the program will terminate and won't crash the kernel.

## Probe Types

| Type | What it attaches to |
|------|-------------------|
| `kprobe` | Entry of a kernel function |
| `kretprobe` | Return of a kernel function |
| `tracepoint` | Stable kernel tracepoints (preferred over kprobes — stable ABI) |
| `uprobe` | Entry of a user-space function |
| `uretprobe` | Return of a user-space function |
| `perf_event` | Hardware/software perf events (CPU cycles, cache misses) |
| `XDP` | Network packet processing at driver level |
| `tc` | Traffic control (network) |
| `socket filter` | Filter packets on a socket |

## eBPF Maps

Maps are the data structures shared between kernel eBPF programs and user-space. Types:

| Map Type | Description |
|----------|-------------|
| `BPF_MAP_TYPE_HASH` | Key-value hash table |
| `BPF_MAP_TYPE_ARRAY` | Integer-indexed array |
| `BPF_MAP_TYPE_PERCPU_HASH` | Per-CPU hash (avoids locking) |
| `BPF_MAP_TYPE_PERCPU_ARRAY` | Per-CPU array |
| `BPF_MAP_TYPE_RINGBUF` | Ring buffer (efficient event streaming, Linux 5.8+) |
| `BPF_MAP_TYPE_STACK_TRACE` | Stack traces (for flame graphs) |

## CO-RE: Compile Once Run Everywhere

Older BCC tools compile eBPF C code at runtime using kernel headers — requiring `kernel-devel` packages to match the running kernel. **CO-RE** (Compile Once Run Everywhere) with `libbpf` and **BTF** (BPF Type Format) enables pre-compiled eBPF programs to run on different kernel versions.

BTF is debug type information embedded in the kernel. With BTF, libbpf can relocate struct field accesses at load time rather than compile time.

Check if your kernel has BTF:
```bash
ls /sys/kernel/btf/vmlinux
zcat /proc/config.gz 2>/dev/null | grep CONFIG_DEBUG_INFO_BTF
```

## The eBPF Tooling Ecosystem

| Tool | Use case |
|------|---------|
| **BCC** | Python/C tools using runtime compilation |
| **bpftrace** | High-level one-liners and scripts |
| **libbpf + CO-RE** | Portable production eBPF programs |
| **Cilium** | Kubernetes networking and security |
| **Falco** | Runtime security detection |
| **Katran** | Facebook load balancer |
| **Pixie** | Kubernetes observability |

## cBPF vs eBPF

| Feature | cBPF | eBPF |
|---------|------|------|
| Registers | 2 (32-bit) | 11 (64-bit) |
| Maps | None | Yes (many types) |
| Program types | Packet filter only | 30+ types |
| Tail calls | No | Yes |
| Helper functions | Limited | 200+ |
| Verifier | Basic | Full safety proof |

## Further Reading

- [ebpf.io — official eBPF site](https://ebpf.io/) — The definitive introduction to eBPF covering the verifier, JIT compilation, map types, and the ecosystem of tools built on it — the best starting point for understanding what this lesson's probe types and map table represent.
- [kernel.org: BPF documentation](https://www.kernel.org/doc/html/latest/bpf/) — Kernel-level BPF documentation covering the verifier rules, syscall interface, map types, and BTF format that underlie everything in the eBPF tooling stack.
- [Cilium: BPF and XDP reference guide](https://docs.cilium.io/en/stable/bpf/) — Cilium's comprehensive BPF reference covering instruction set, map types, helper functions, CO-RE, and XDP — more detailed than the kernel docs for many topics.
- [LWN: A thorough introduction to eBPF](https://lwn.net/Articles/740157/) — LWN's in-depth introduction explaining the verifier's safety guarantees, JIT compilation, and how eBPF differs from kernel modules in terms of safety and portability.
- [Brendan Gregg: Learn eBPF tracing](https://www.brendangregg.com/blog/2019-01-01/learn-ebpf-tracing.html) — Brendan Gregg's recommended learning path for eBPF tracing, covering when to use bpftrace vs BCC vs libbpf and linking to the best resources for each.
