# Exercise: systemd Service Hardening

## Setup

```bash
mkdir -p ~/practice/systemd_hardening
```

## Task 1: Check Capabilities of Running Processes

```bash
# Your shell's effective capabilities
echo "Current shell capabilities:"
cat /proc/$$/status | grep -i "^Cap"

# Decode to human-readable names
capsh --decode=$(awk '/^CapEff/{print $2}' /proc/$$/status) 2>/dev/null || \
    echo "(capsh not available — raw bitmask above)"

# Check a system process
cat /proc/1/status | grep -i "^Cap"
```

## Task 2: Analyze Security of an Existing Service

```bash
# Score sshd's hardening level
systemd-analyze security sshd.service 2>/dev/null || \
    systemd-analyze security ssh.service 2>/dev/null || \
    echo "Try: systemd-analyze security <any.service>"

# List available services and pick one to analyze
systemctl list-units --type=service --state=running | head -10
```

## Task 3: Create a Minimal Test Service

```bash
# Create the binary the service will run
cat > ~/practice/systemd_hardening/test_app.sh << 'EOF'
#!/bin/bash
while true; do
    echo "$(date): running as $(id), PID=$$"
    sleep 5
done
EOF
chmod +x ~/practice/systemd_hardening/test_app.sh

# Create the unit file
sudo tee /etc/systemd/system/hardening-test.service << 'EOF'
[Unit]
Description=Hardening Test Service
After=network.target

[Service]
Type=simple
ExecStart=/root/practice/systemd_hardening/test_app.sh
Restart=on-failure

# Basic hardening
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=strict
ProtectHome=yes
CapabilityBoundingSet=
LimitNOFILE=1024

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start hardening-test.service
sudo systemctl status hardening-test.service
```

## Task 4: Measure the Security Score

```bash
systemd-analyze security hardening-test.service 2>/dev/null | head -30
```

Note the "Overall exposure level" — a lower number is better. Most default services score 9+.

## Task 5: Read Service Capability Status from /proc

```bash
# Find the PID of our test service
SVC_PID=$(systemctl show -p MainPID hardening-test.service | cut -d= -f2)
echo "Service PID: $SVC_PID"

# Read its capabilities
if [ -n "$SVC_PID" ] && [ "$SVC_PID" != "0" ]; then
    echo "Capabilities:"
    cat /proc/$SVC_PID/status | grep "^Cap"
    echo ""
    echo "CapBnd (bounding set) = 0 means no capabilities"
fi
```

## Task 6: Observe PrivateTmp Isolation

```bash
# Create a file in /tmp from our shell
touch /tmp/shell_file_$$.txt
ls /tmp/ | grep shell_file

# Run a command inside the service's namespace (via nsenter or systemd-run)
# The service with PrivateTmp=yes has its own /tmp
SVC_PID=$(systemctl show -p MainPID hardening-test.service | cut -d= -f2)
if [ -n "$SVC_PID" ] && [ "$SVC_PID" != "0" ]; then
    echo "Host /tmp contents visible to service (should be isolated):"
    sudo nsenter -m --target $SVC_PID -- ls /tmp/ 2>/dev/null || \
        echo "nsenter not available — isolation is active but can't inspect"
fi

# Cleanup
rm -f /tmp/shell_file_$$.txt
```

## Task 7: Write a Hardened Production Unit File

```bash
cat > ~/practice/systemd_hardening/hardened.service << 'EOF'
[Unit]
Description=Example Hardened Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/sleep infinity

# Identity — drop to a non-root user
DynamicUser=yes

# No privilege escalation
NoNewPrivileges=yes

# Drop all capabilities
CapabilityBoundingSet=

# Filesystem
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=strict
ProtectHome=yes

# Syscall filter
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

# Namespace protection
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictNamespaces=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes

# Network
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

# Resources
LimitNOFILE=4096
MemoryMax=256M
TasksMax=64

[Install]
WantedBy=multi-user.target
EOF
cat ~/practice/systemd_hardening/hardened.service
```

## Cleanup

```bash
sudo systemctl stop hardening-test.service
sudo systemctl disable hardening-test.service 2>/dev/null
sudo rm -f /etc/systemd/system/hardening-test.service
sudo systemctl daemon-reload
```

## Expected Outcome

- `/proc/<pid>/status` Cap* fields are readable and decodable
- `systemd-analyze security` scores a running service
- `hardening-test.service` starts with NoNewPrivileges=yes and CapabilityBoundingSet=
- PrivateTmp isolation is confirmed
- `~/practice/systemd_hardening/hardened.service` — a complete hardened unit file template
