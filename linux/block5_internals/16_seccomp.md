# seccomp — Syscall Filtering

seccomp (Secure Computing Mode) restricts which system calls a process may make. It's the primary mechanism for limiting the kernel attack surface from compromised containerized processes.

## How seccomp Works

seccomp operates at the kernel level via the `seccomp(2)` syscall. When a process enters seccomp filter mode, every subsequent syscall is checked against a BPF program before the kernel executes it:

```
process → syscall → seccomp BPF filter → allow / kill / return error / trap
```

The filter sees: syscall number, arguments, architecture. It cannot see memory contents.

Two modes:

| Mode | Description |
|------|-------------|
| `SECCOMP_MODE_STRICT` | Only `read`, `write`, `_exit`, `sigreturn` allowed — no filter needed |
| `SECCOMP_MODE_FILTER` | BPF program defines the allowlist/denylist |

## /proc/self/status — Seccomp Field

```bash
# Check if the current process has seccomp enabled
grep Seccomp /proc/self/status
# Seccomp: 0   ← 0=disabled, 1=strict, 2=filter mode

grep Seccomp /proc/$$/status   # same for current shell
```

## seccomp Profiles in Docker

Docker uses seccomp to restrict containers to a safe subset of syscalls. The default profile blocks ~44 dangerous syscalls.

```bash
# Run a container with the default seccomp profile (automatic)
docker run --rm ubuntu ls

# Run without any seccomp restrictions (for comparison/debugging)
docker run --rm --security-opt seccomp=unconfined ubuntu grep Seccomp /proc/self/status

# Inspect which syscalls the default profile allows
docker info 2>/dev/null | grep -i seccomp
```

### Writing a Custom seccomp Profile

Profiles are JSON files with a default action and a syscall list:

```json
{
    "defaultAction": "SCMP_ACT_ERRNO",
    "architectures": ["SCMP_ARCH_X86_64"],
    "syscalls": [
        {
            "names": ["read", "write", "exit", "exit_group", "fstat",
                      "mmap", "mprotect", "munmap", "brk", "arch_prctl",
                      "access", "openat", "close", "stat", "getdents64",
                      "ioctl", "set_tid_address", "set_robust_list",
                      "prlimit64", "futex"],
            "action": "SCMP_ACT_ALLOW"
        }
    ]
}
```

**Actions:**
| Action | Effect |
|--------|--------|
| `SCMP_ACT_ALLOW` | Let the syscall proceed |
| `SCMP_ACT_ERRNO` | Return an error (usually `EPERM`) |
| `SCMP_ACT_KILL` | Kill the process with `SIGSYS` |
| `SCMP_ACT_TRAP` | Deliver `SIGSYS` (catchable) |
| `SCMP_ACT_LOG` | Log and allow (useful for profiling) |
| `SCMP_ACT_TRACE` | Notify a ptracer |

```bash
# Apply a custom profile to a Docker container
docker run --rm --security-opt seccomp=/path/to/profile.json ubuntu bash

# Deny just one syscall (mkdir) — allowlist everything else
cat > /tmp/deny_mkdir.json << 'EOF'
{
    "defaultAction": "SCMP_ACT_ALLOW",
    "syscalls": [
        { "names": ["mkdir", "mkdirat"], "action": "SCMP_ACT_ERRNO" }
    ]
}
EOF
docker run --rm --security-opt seccomp=/tmp/deny_mkdir.json ubuntu bash -c \
    "mkdir /tmp/test 2>&1; echo exit: \$?"
```

## Observing seccomp Behavior with strace

When a syscall is blocked by seccomp with `SCMP_ACT_ERRNO`, it returns `EPERM`. With `SCMP_ACT_KILL`, strace shows `SIGSYS`:

```bash
# Trace what happens when mkdir is seccomp-blocked
docker run --rm --security-opt seccomp=/tmp/deny_mkdir.json ubuntu \
    strace mkdir /tmp/test 2>&1 | grep -E "mkdir|EPERM|SIGSYS"

# Without seccomp: syscall succeeds
strace mkdir /tmp/strace_test 2>&1 | grep "mkdir"
rmdir /tmp/strace_test
```

## Building a Minimal Allowlist (Profiling Approach)

The safe way to build a seccomp profile is to record all syscalls the application actually uses, then deny everything else.

```bash
# 1. Record all syscalls made by a command using strace summary
strace -c ls /tmp 2>&1
# Shows count and name of each syscall used

# 2. Record all unique syscall names
strace -e trace=all ls /tmp 2>/tmp/ls_trace.txt
grep "^[a-z]" /tmp/ls_trace.txt | cut -d'(' -f1 | sort -u

# 3. For a running process, audit mode (log but don't block)
# Use SCMP_ACT_LOG as defaultAction during testing phase
```

## Kubernetes and seccomp

Kubernetes supports seccomp profiles via Pod security context:

```yaml
apiVersion: v1
kind: Pod
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault    # use the container runtime's default profile
      # type: Localhost
      # localhostProfile: profiles/my-app.json
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
```

`RuntimeDefault` uses Docker's/containerd's built-in default profile — a reasonable baseline for most workloads.

## Checking seccomp Status of Running Processes

```bash
# Check all running processes for their seccomp status
awk '{if ($1 == "Seccomp:") print FILENAME, $2}' /proc/*/status 2>/dev/null \
    | grep -v " 0$" \
    | head -20
# Seccomp: 2 means seccomp filter mode is active

# Check a specific container's PID
CPID=$(docker inspect --format '{{.State.Pid}}' mycontainer 2>/dev/null)
grep Seccomp /proc/$CPID/status 2>/dev/null
```

## What seccomp Cannot Do

- Filter based on file names or network destinations (seccomp only sees syscall numbers and register arguments, not memory)
- Prevent capabilities a process already has (use capabilities for that — block3/04)
- Stop a process from using syscalls you didn't know it needed (profile first)

## Further Reading

- [seccomp(2) — man7.org](https://man7.org/linux/man-pages/man2/seccomp.2.html) — the authoritative reference for seccomp: `SECCOMP_MODE_FILTER`, the `struct seccomp_data` layout, all `SECCOMP_RET_*` actions, `SECCOMP_FILTER_FLAG_TSYNC`, and the `seccomp_unotify` notification mechanism.
- [Kernel seccomp documentation — kernel.org](https://www.kernel.org/doc/html/latest/userspace-api/seccomp_filter.html) — kernel documentation for seccomp BPF filter mode: the cBPF instruction set available to filters, the `seccomp_data` fields the filter can access, and the decision hierarchy for multiple filters.
- [Docker seccomp profiles](https://docs.docker.com/engine/security/seccomp/) — Docker's documentation of its default seccomp profile (the ~44 syscalls it blocks), the JSON profile format, and how to apply custom profiles with `--security-opt seccomp=`.
- [LWN — Seccomp and seccomp-bpf](https://lwn.net/Articles/656307/) — LWN article explaining the evolution from strict mode to BPF filter mode, the design of `struct seccomp_data`, and practical guidance for building allowlists for production services.
