# Exercise: SELinux and AppArmor

## Setup

```bash
mkdir -p ~/practice/mac
sudo apt-get install -y apparmor-utils 2>/dev/null || true
```

## Task 1: Check AppArmor Status

```bash
# Is AppArmor enabled?
cat /sys/module/apparmor/parameters/enabled

# Full status
sudo aa-status 2>/dev/null || sudo apparmor_status 2>/dev/null || echo "AppArmor not available"

# List loaded profiles and their modes
sudo aa-status 2>/dev/null | grep -E "enforce|complain" | head -20
```

## Task 2: Browse Existing Profiles

```bash
# List all profile files
ls /etc/apparmor.d/ | head -20

# Read a simple profile
cat /etc/apparmor.d/usr.bin.man 2>/dev/null || \
    ls /etc/apparmor.d/ | head -5 | xargs -I{} echo /etc/apparmor.d/{}
```

## Task 3: Write and Load a Custom AppArmor Profile

Create a profile for a simple shell script:

```bash
# Create the script to be confined
cat > /usr/local/bin/aa_test_script << 'EOF'
#!/bin/bash
cat /etc/hostname        # should be allowed
cat /etc/shadow 2>&1     # should be denied by profile
echo "done"
EOF
chmod +x /usr/local/bin/aa_test_script

# Run it without a profile (unconfined) — both accesses succeed
echo "=== Without profile ==="
/usr/local/bin/aa_test_script
```

```bash
# Write the AppArmor profile (deny access to /etc/shadow)
sudo tee /etc/apparmor.d/usr.local.bin.aa_test_script << 'EOF'
#include <tunables/global>

/usr/local/bin/aa_test_script {
  #include <abstractions/base>
  #include <abstractions/bash>

  /usr/local/bin/aa_test_script r,
  /bin/bash                      r,
  /bin/bash                      ix,
  /usr/bin/cat                   ix,
  /etc/hostname                  r,
  /dev/tty                       rw,
  /proc/self/fd/                 r,

  deny /etc/shadow               r,
}
EOF

# Load it in complain mode first (log but don't block)
sudo apparmor_parser -r -C /etc/apparmor.d/usr.local.bin.aa_test_script 2>/dev/null
echo "=== In complain mode ==="
sudo aa-complain /etc/apparmor.d/usr.local.bin.aa_test_script 2>/dev/null || true
/usr/local/bin/aa_test_script
```

## Task 4: Check AppArmor Denials in Logs

```bash
# Look for AppArmor messages in recent kernel logs
journalctl -k --no-pager -n 50 2>/dev/null | grep -i apparmor | tail -10
dmesg | grep -i apparmor | tail -10

# Check syslog
grep -i apparmor /var/log/syslog 2>/dev/null | tail -10 || \
    echo "No AppArmor messages in syslog (may be in journal only)"
```

## Task 5: Profile Modes — Complain vs Enforce

```bash
# Check current mode of the test profile
sudo aa-status 2>/dev/null | grep aa_test_script || \
    sudo apparmor_status 2>/dev/null | grep aa_test_script

# Switch to enforce mode (violations will be blocked)
sudo aa-enforce /etc/apparmor.d/usr.local.bin.aa_test_script 2>/dev/null || true

echo "=== In enforce mode ==="
/usr/local/bin/aa_test_script

# Switch back to complain for cleanup
sudo aa-complain /etc/apparmor.d/usr.local.bin.aa_test_script 2>/dev/null || true
```

## Task 6: Write a Summary Script

```bash
cat > ~/practice/mac/mac_summary.sh << 'EOF'
#!/bin/bash
echo "=== MAC Status ==="

# AppArmor
if [ -f /sys/module/apparmor/parameters/enabled ]; then
    ENABLED=$(cat /sys/module/apparmor/parameters/enabled)
    echo "AppArmor enabled: $ENABLED"
    if command -v aa-status > /dev/null 2>&1; then
        sudo aa-status --json 2>/dev/null | grep -oE '"(enforce|complain)": [0-9]+' || \
            sudo aa-status 2>/dev/null | grep -E "profile|enforce|complain" | head -5
    fi
else
    echo "AppArmor: not loaded"
fi

# SELinux (RHEL/Fedora)
if command -v getenforce > /dev/null 2>&1; then
    echo "SELinux mode: $(getenforce)"
else
    echo "SELinux: not available on this system (Ubuntu uses AppArmor)"
fi
EOF
chmod +x ~/practice/mac/mac_summary.sh
bash ~/practice/mac/mac_summary.sh
```

## Cleanup

```bash
# Remove the test profile and script
sudo aa-disable /etc/apparmor.d/usr.local.bin.aa_test_script 2>/dev/null || true
sudo rm -f /etc/apparmor.d/usr.local.bin.aa_test_script
sudo rm -f /usr/local/bin/aa_test_script
```

## Expected Outcome

- AppArmor is loaded and `aa-status` shows profiles
- A custom AppArmor profile was created, loaded, and tested in complain mode
- `~/practice/mac/mac_summary.sh` reports AppArmor status
- AppArmor deny messages are visible in journal/dmesg
