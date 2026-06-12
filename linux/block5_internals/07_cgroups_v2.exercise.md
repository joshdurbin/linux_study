# Exercise: cgroups v2

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: Confirm cgroups v2

Verify the system uses cgroups v2 (unified hierarchy):

```bash
# Check mount type
mount | grep cgroup

# Should show: cgroup2 on /sys/fs/cgroup
# If it shows multiple cgroup (v1) mounts, the system uses v1 or hybrid mode
```

## Task 2: Explore the cgroup Hierarchy

```bash
# List the top-level cgroup directory
ls /sys/fs/cgroup/

# See available controllers
cat /sys/fs/cgroup/cgroup.controllers

# See which controllers are propagated to children
cat /sys/fs/cgroup/cgroup.subtree_control

# Explore systemd's organizational structure
ls /sys/fs/cgroup/system.slice/ 2>/dev/null | head -10
ls /sys/fs/cgroup/user.slice/ 2>/dev/null | head -5
```

## Task 3: Find Your Process's cgroup

```bash
# Read your current cgroup assignment
echo "My cgroup:"
cat /proc/self/cgroup

# Extract just the path
MY_CGROUP_PATH=$(cat /proc/self/cgroup | cut -d: -f3)
echo "Cgroup path: $MY_CGROUP_PATH"
echo "Full filesystem path: /sys/fs/cgroup${MY_CGROUP_PATH}"
```

Save this to your practice notes:
```bash
cat /proc/self/cgroup > ~/practice/my_cgroup.txt
echo "Full path: /sys/fs/cgroup$(cat /proc/self/cgroup | cut -d: -f3)" >> ~/practice/my_cgroup.txt
cat ~/practice/my_cgroup.txt
```

## Task 4: Read Memory Stats for Your cgroup

```bash
# Get the full path to your cgroup
CG_PATH="/sys/fs/cgroup$(cat /proc/self/cgroup | cut -d: -f3)"

echo "cgroup directory contents:"
ls "$CG_PATH" 2>/dev/null

# Try reading memory stats
echo "Memory current:"
cat "$CG_PATH/memory.current" 2>/dev/null || echo "(not available at this level)"

echo "PIDs current:"
cat "$CG_PATH/pids.current" 2>/dev/null || echo "(not available at this level)"
```

## Task 5: View systemd cgroup Tree

Use systemd tools to visualize the cgroup hierarchy:

```bash
# Show hierarchical cgroup tree
systemd-cgls 2>/dev/null | head -30

# Or use the systemctl status tree view
systemctl status 2>/dev/null | head -20

# Check PID 1's cgroup
cat /proc/1/cgroup
```

## Task 6: Check a Service's Resource Usage

```bash
# Find the cgroup for the SSH daemon (if running)
SSHD_CG=$(systemctl show -P ControlGroup sshd.service 2>/dev/null || \
          systemctl show -P ControlGroup ssh.service 2>/dev/null)

if [ -n "$SSHD_CG" ]; then
    echo "sshd cgroup: $SSHD_CG"
    echo "Memory usage:"
    cat "/sys/fs/cgroup${SSHD_CG}/memory.current" 2>/dev/null
    echo "PIDs in group:"
    cat "/sys/fs/cgroup${SSHD_CG}/cgroup.procs" 2>/dev/null | wc -l
else
    echo "sshd service not found, checking another service..."
    systemctl list-units --type=service --state=running --no-pager | head -5
fi
```

## Expected Outcome

- `~/practice/my_cgroup.txt` exists and contains the current process's cgroup path
- You can navigate `/sys/fs/cgroup` and understand the hierarchy
- You know how to read memory and pid stats from a cgroup
