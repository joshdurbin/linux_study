#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /proc/self/status has Cap fields
check "/proc/self/status has CapEff field" \
  "grep -q '^CapEff:' /proc/self/status"

check "/proc/self/status has CapBnd field" \
  "grep -q '^CapBnd:' /proc/self/status"

# Check 3: systemd-analyze is available
check "systemd-analyze is available" \
  "command -v systemd-analyze > /dev/null 2>&1"

# Check 4: systemd-analyze security subcommand works
check "systemd-analyze security subcommand works" \
  "systemd-analyze security --version > /dev/null 2>&1 || \
   systemd-analyze security sshd.service > /dev/null 2>&1 || \
   systemd-analyze security ssh.service > /dev/null 2>&1 || \
   systemctl list-units --type=service --state=running -q | head -1 | \
     awk '{print \$1}' | xargs -I{} systemd-analyze security {} > /dev/null 2>&1"

# Check 5: practice directory exists
check "~/practice/systemd_hardening directory exists" \
  "[ -d \$HOME/practice/systemd_hardening ]"

# Check 6: test_app.sh exists and is executable
check "test_app.sh exists and is executable" \
  "[ -x \$HOME/practice/systemd_hardening/test_app.sh ]"

# Check 7: hardened.service template exists
check "hardened.service template exists" \
  "[ -f \$HOME/practice/systemd_hardening/hardened.service ]"

# Check 8: hardened.service has NoNewPrivileges
check "hardened.service has NoNewPrivileges=yes" \
  "grep -q 'NoNewPrivileges=yes' \$HOME/practice/systemd_hardening/hardened.service"

# Check 9: hardened.service drops capabilities
check "hardened.service has empty CapabilityBoundingSet" \
  "grep -q 'CapabilityBoundingSet=' \$HOME/practice/systemd_hardening/hardened.service"

# Check 10: hardened.service has PrivateTmp
check "hardened.service has PrivateTmp=yes" \
  "grep -q 'PrivateTmp=yes' \$HOME/practice/systemd_hardening/hardened.service"

# Check 11: hardened.service has ProtectSystem
check "hardened.service has ProtectSystem" \
  "grep -q 'ProtectSystem' \$HOME/practice/systemd_hardening/hardened.service"

# Check 12: hardened.service has SystemCallFilter
check "hardened.service has SystemCallFilter" \
  "grep -q 'SystemCallFilter' \$HOME/practice/systemd_hardening/hardened.service"

# Check 13: hardened.service has resource limits
check "hardened.service has LimitNOFILE or MemoryMax" \
  "grep -qE 'LimitNOFILE|MemoryMax' \$HOME/practice/systemd_hardening/hardened.service"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
