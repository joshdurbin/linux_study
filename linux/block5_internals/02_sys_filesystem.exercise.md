# Exercise: /sys and sysctl

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: Explore /sys/class/net

Look at the network interface information exposed through sysfs:

```bash
ls /sys/class/net/

# For each interface you find, check its state
for iface in $(ls /sys/class/net/); do
  echo "$iface: $(cat /sys/class/net/$iface/operstate 2>/dev/null)"
done
```

## Task 2: Read vm.swappiness

Read the current swappiness value two ways:

```bash
# Method 1: via sysctl
sysctl vm.swappiness

# Method 2: directly from /proc/sys
cat /proc/sys/vm/swappiness
```

Save the value to your notes:
```bash
echo "vm.swappiness = $(sysctl -n vm.swappiness)" > ~/practice/sysctl_notes.txt
```

## Task 3: Read net.ipv4.ip_forward

Check whether IP forwarding is enabled:

```bash
sysctl net.ipv4.ip_forward
```

A value of `0` means disabled (normal for a workstation), `1` means enabled (required for a router/NAT host).

Append to your notes:
```bash
echo "net.ipv4.ip_forward = $(sysctl -n net.ipv4.ip_forward)" >> ~/practice/sysctl_notes.txt
```

## Task 4: Change vm.swappiness Temporarily

Try changing swappiness without a reboot (requires sudo or root):

```bash
# Read current value
sysctl vm.swappiness

# Set it to a different value
sudo sysctl -w vm.swappiness=15

# Verify it changed
sysctl vm.swappiness

# Set it back
sudo sysctl -w vm.swappiness=60
```

Record what you observed:
```bash
echo "Temporarily changed swappiness to 15 and back to 60" >> ~/practice/sysctl_notes.txt
```

## Task 5: Explore Kernel Parameters

Look at a few more useful parameters:

```bash
# Max PIDs
sysctl kernel.pid_max

# Max open file descriptors
sysctl fs.file-max

# Current open file count
cat /proc/sys/fs/file-nr

# Append findings
sysctl kernel.pid_max fs.file-max >> ~/practice/sysctl_notes.txt
```

## Task 6: Create a sysctl Config Snippet

Create a file showing what you'd put in a real sysctl config:

```bash
cat >> ~/practice/sysctl_notes.txt << 'EOF'

# Sample sysctl.d snippet
vm.swappiness = 10
net.ipv4.ip_forward = 0
fs.file-max = 2097152
kernel.pid_max = 65536
EOF
```

## Expected Outcome

- `~/practice/sysctl_notes.txt` exists and contains `vm.swappiness` value
- You understand how to read and temporarily change kernel parameters
