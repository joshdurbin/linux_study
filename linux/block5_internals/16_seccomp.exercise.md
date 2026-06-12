# Exercise: seccomp

## Setup

```bash
mkdir -p ~/practice/seccomp
```

## Task 1: Check seccomp Status of the Current Shell

```bash
# Is seccomp active in this shell?
grep Seccomp /proc/self/status
# 0 = disabled, 1 = strict, 2 = filter mode

# Check a few running processes
for pid in 1 $(pgrep bash | head -3); do
    val=$(awk '/^Seccomp:/{print $2}' /proc/$pid/status 2>/dev/null)
    comm=$(cat /proc/$pid/comm 2>/dev/null)
    echo "PID $pid ($comm): Seccomp=$val"
done
```

## Task 2: Profile Syscalls Used by a Command

Use strace (introduced in block5/03) to see which syscalls `ls` actually uses:

```bash
# Summary mode: counts per syscall
strace -c ls /etc 2>&1 | tail -20

# List unique syscall names
strace ls /tmp 2>&1 | grep -oE '^[a-z_]+' | sort -u

# Save syscall list to a file
strace ls /tmp 2>~/practice/seccomp/ls_syscalls.txt
grep -oE '^[a-z_0-9]+' ~/practice/seccomp/ls_syscalls.txt | sort -u \
    > ~/practice/seccomp/ls_names.txt
cat ~/practice/seccomp/ls_names.txt
```

## Task 3: Write a seccomp Profile

Based on the syscall list, write a minimal allowlist profile:

```bash
cat > ~/practice/seccomp/ls_profile.json << 'EOF'
{
    "defaultAction": "SCMP_ACT_ERRNO",
    "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_AARCH64"],
    "syscalls": [
        {
            "names": [
                "read", "write", "close", "fstat", "lstat", "stat",
                "mmap", "mprotect", "munmap", "brk", "access",
                "openat", "getdents64", "exit_group", "ioctl",
                "arch_prctl", "set_tid_address", "set_robust_list",
                "prlimit64", "futex", "statfs", "getxattr",
                "lgetxattr", "readlink"
            ],
            "action": "SCMP_ACT_ALLOW"
        }
    ]
}
EOF
cat ~/practice/seccomp/ls_profile.json
```

## Task 4: Write a Deny-One Profile

Write a profile that allows everything EXCEPT mkdir:

```bash
cat > ~/practice/seccomp/deny_mkdir.json << 'EOF'
{
    "defaultAction": "SCMP_ACT_ALLOW",
    "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_AARCH64"],
    "syscalls": [
        {
            "names": ["mkdir", "mkdirat"],
            "action": "SCMP_ACT_ERRNO"
        }
    ]
}
EOF
```

## Task 5: Test the Profile with Docker (if available)

```bash
if command -v docker > /dev/null 2>&1; then
    # Test that mkdir is blocked by the deny_mkdir profile
    echo "Testing deny_mkdir profile:"
    docker run --rm \
        --security-opt seccomp=~/practice/seccomp/deny_mkdir.json \
        ubuntu bash -c "mkdir /tmp/blocked_test 2>&1; echo exit:\$?"

    # Compare: without seccomp, mkdir succeeds
    echo ""
    echo "Without seccomp restriction:"
    docker run --rm --security-opt seccomp=unconfined \
        ubuntu bash -c "mkdir /tmp/allowed_test 2>&1 && echo 'mkdir succeeded' && rmdir /tmp/allowed_test"

    # Check seccomp status inside a container
    echo ""
    echo "Seccomp status inside container:"
    docker run --rm ubuntu grep Seccomp /proc/self/status
else
    echo "Docker not available — checking seccomp kernel support instead"
    grep -q "CONFIG_SECCOMP=y" /boot/config-$(uname -r) 2>/dev/null \
        && echo "Kernel has CONFIG_SECCOMP enabled" \
        || cat /proc/sys/kernel/seccomp 2>/dev/null \
        || echo "Check /proc/self/status Seccomp field for runtime status"
fi
```

## Task 6: Find Processes Running with seccomp Filters

```bash
# Scan all processes for active seccomp filter mode (mode 2)
echo "Processes with seccomp filter active (Seccomp: 2):"
for status in /proc/[0-9]*/status; do
    pid=$(echo $status | cut -d/ -f3)
    seccomp=$(awk '/^Seccomp:/{print $2}' $status 2>/dev/null)
    if [ "$seccomp" = "2" ]; then
        comm=$(cat /proc/$pid/comm 2>/dev/null)
        echo "  PID $pid: $comm"
    fi
done | head -20
```

## Task 7: Write a Check Script

```bash
cat > ~/practice/seccomp/check_seccomp.sh << 'EOF'
#!/bin/bash
# Check which running processes have seccomp filtering active

FILTERED=0
TOTAL=0

for status in /proc/[0-9]*/status; do
    pid=$(echo "$status" | cut -d/ -f3)
    seccomp=$(awk '/^Seccomp:/{print $2}' "$status" 2>/dev/null)
    [ -z "$seccomp" ] && continue
    TOTAL=$((TOTAL + 1))
    [ "$seccomp" -eq 2 ] && FILTERED=$((FILTERED + 1))
done

echo "Processes with seccomp filter: $FILTERED / $TOTAL"
echo "Kernel seccomp support: $(grep Seccomp /proc/self/status | awk '{print $2}')"
EOF
chmod +x ~/practice/seccomp/check_seccomp.sh
bash ~/practice/seccomp/check_seccomp.sh
```

## Expected Outcome

- `/proc/self/status` Seccomp field is readable and returns 0, 1, or 2
- `strace -c ls` shows the syscalls ls actually uses
- `~/practice/seccomp/ls_profile.json` — allowlist profile for ls
- `~/practice/seccomp/deny_mkdir.json` — denylist profile blocking mkdir/mkdirat
- `~/practice/seccomp/check_seccomp.sh` — scans all processes for seccomp filter status
