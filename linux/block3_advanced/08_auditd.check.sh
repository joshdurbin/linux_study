#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: auditd is installed
check "auditd is installed" \
  "command -v auditctl > /dev/null 2>&1"

# Check 2: ausearch is available
check "ausearch is available" \
  "command -v ausearch > /dev/null 2>&1"

# Check 3: aureport is available
check "aureport is available" \
  "command -v aureport > /dev/null 2>&1"

# Check 4: auditd service is running
check "auditd service is running" \
  "systemctl is-active auditd > /dev/null 2>&1 || pgrep auditd > /dev/null 2>&1"

# Check 5: auditctl -s shows audit is enabled
check "audit subsystem is enabled" \
  "sudo auditctl -s 2>/dev/null | grep -q 'enabled [12]'"

# Check 6: audit practice directory exists
check "~/practice/audit directory exists" \
  "[ -d \$HOME/practice/audit ]"

# Check 7: can add and list a watch rule
check "auditctl can add a watch rule" \
  "sudo auditctl -w /tmp -p wa -k check_test_rule 2>/dev/null && sudo auditctl -l 2>/dev/null | grep -q check_test_rule && sudo auditctl -W /tmp -p wa -k check_test_rule 2>/dev/null"

# Check 8: ausearch can run without error
check "ausearch -ts recent runs without fatal error" \
  "sudo ausearch -ts recent > /dev/null 2>&1; [ \$? -ne 255 ]"

# Check 9: aureport can run without error
check "aureport runs without fatal error" \
  "sudo aureport > /dev/null 2>&1; [ \$? -ne 255 ]"

# Check 10: audit log file exists or auditd writes to journal
check "audit log exists or auditd uses journal" \
  "[ -f /var/log/audit/audit.log ] || journalctl -u auditd --no-pager -n 1 > /dev/null 2>&1"

# Check 11: my_rules.rules file exists
check "my_rules.rules exists in practice/audit" \
  "[ -f \$HOME/practice/audit/my_rules.rules ]"

# Check 12: rules file has -w watch entries
check "my_rules.rules contains watch rules (-w)" \
  "grep -q '^-w' \$HOME/practice/audit/my_rules.rules"

# Check 13: rules file has -k key tags
check "my_rules.rules contains key tags (-k)" \
  "grep -q '\-k ' \$HOME/practice/audit/my_rules.rules"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
