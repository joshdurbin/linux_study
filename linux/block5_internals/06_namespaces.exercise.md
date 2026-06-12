# Exercise: Linux Namespaces

## Setup

```bash
mkdir -p ~/practice
which lsns || sudo apt-get install -y util-linux
```

## Task 1: List Current Namespaces

View all namespaces visible on the system:

```bash
lsns
```

This shows namespace type, inode, number of processes, PID, and the command of the first process in that namespace.

View namespaces of your current shell:
```bash
lsns -p $$
```

## Task 2: Inspect Namespace Files in /proc

Look at the namespace symlinks for your shell and PID 1:

```bash
# Your shell's namespaces
echo "=== Your shell's namespaces ==="
ls -la /proc/$$/ns/

# PID 1's namespaces
echo "=== PID 1's namespaces ==="
ls -la /proc/1/ns/

# Compare them — which are shared?
echo "=== Comparing namespaces ==="
for ns in ipc mnt net pid uts user; do
    shell_ns=$(readlink /proc/$$/ns/$ns)
    pid1_ns=$(readlink /proc/1/ns/$ns 2>/dev/null)
    if [ "$shell_ns" = "$pid1_ns" ]; then
        echo "SHARED: $ns ($shell_ns)"
    else
        echo "DIFFERENT: $ns (shell=$shell_ns, pid1=$pid1_ns)"
    fi
done
```

## Task 3: Create a UTS Namespace Isolation

Use `unshare` to change the hostname in an isolated environment:

```bash
# Get current hostname
echo "Host hostname: $(hostname)"

# Run in isolated UTS namespace
sudo unshare --uts bash -c '
    hostname mycontainer
    echo "Inside namespace hostname: $(hostname)"
    echo "PID in namespace: $$"
'

# Verify host hostname is unchanged
echo "Host hostname after: $(hostname)"
```

## Task 4: Document the 8 Namespace Types

Create notes about namespaces for future reference:

```bash
cat > ~/practice/namespace_notes.txt << 'EOF'
Linux Namespace Types
=====================

1. PID (CLONE_NEWPID)
   - Isolates process IDs
   - Container processes get their own PID space starting from 1
   - Host can see all PIDs; container only sees its own

2. NET (CLONE_NEWNET)
   - Isolates network interfaces, routing tables, iptables rules
   - Each container can have its own eth0, IP, ports
   - Connected to host via veth pairs

3. MNT (CLONE_NEWNS)
   - Isolates mount points
   - Container sees its image as the filesystem root
   - Host mounts are invisible inside

4. UTS (CLONE_NEWUTS)
   - Isolates hostname and NIS domain name
   - Containers can have unique hostnames

5. IPC (CLONE_NEWIPC)
   - Isolates SysV IPC and POSIX message queues
   - Prevents IPC interference between containers

6. USER (CLONE_NEWUSER)
   - Isolates UIDs and GIDs
   - Process can be "root" inside (UID 0) but map to unprivileged UID on host

7. TIME (CLONE_NEWTIME)
   - Isolates system clock offsets (Linux 5.6+)
   - Each namespace can have a different clock offset

8. CGROUP (CLONE_NEWCGROUP)
   - Isolates cgroup root directory view
   - Container sees its cgroup subtree as the root
EOF

cat ~/practice/namespace_notes.txt
```

## Task 5: View Namespace Membership of a Process

Check what namespace a specific process belongs to:

```bash
# Your shell
echo "Shell namespace inode (PID ns): $(readlink /proc/$$/ns/pid)"

# Compare two shells — they should share all namespaces
bash -c 'echo "Child shell namespace: $(readlink /proc/$$/ns/pid)"'
```

## Expected Outcome

- `~/practice/namespace_notes.txt` exists with at least 3 namespace types described
- You can use `lsns` to list namespaces
- You can use `unshare --uts` to demonstrate hostname isolation
