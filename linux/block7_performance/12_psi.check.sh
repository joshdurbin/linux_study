#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /proc/pressure/cpu exists and is readable
check "/proc/pressure/cpu is readable" \
  "[ -r /proc/pressure/cpu ] && grep -q 'avg10' /proc/pressure/cpu"

# Check 2: /proc/pressure/memory exists and is readable
check "/proc/pressure/memory is readable" \
  "[ -r /proc/pressure/memory ] && grep -q 'avg10' /proc/pressure/memory"

# Check 3: /proc/pressure/io exists and is readable
check "/proc/pressure/io is readable" \
  "[ -r /proc/pressure/io ] && grep -q 'avg10' /proc/pressure/io"

# Check 4: PSI files contain 'some' line
check "/proc/pressure/cpu has 'some' line" \
  "grep -q '^some' /proc/pressure/cpu"

# Check 5: /proc/pressure/memory has both 'some' and 'full' lines
check "/proc/pressure/memory has 'some' and 'full' lines" \
  "grep -q '^some' /proc/pressure/memory && grep -q '^full' /proc/pressure/memory"

# Check 6: /proc/pressure/io has both 'some' and 'full' lines
check "/proc/pressure/io has 'some' and 'full' lines" \
  "grep -q '^some' /proc/pressure/io && grep -q '^full' /proc/pressure/io"

# Check 7: awk can extract avg10 from cpu pressure
check "awk extracts avg10 value from /proc/pressure/cpu" \
  "val=\$(awk '/^some/ {for(i=1;i<=NF;i++) if(\$i~/^avg10=/) {split(\$i,a,\"=\"); print a[2]}}' /proc/pressure/cpu); [ -n \"\$val\" ]"

# Check 8: total field is a number (microseconds since boot)
check "/proc/pressure/io 'some' line has numeric total field" \
  "awk '/^some/ {print \$NF}' /proc/pressure/io | grep -qE 'total=[0-9]+'"

# Check 9: psi practice directory exists
check "~/practice/psi directory exists" \
  "[ -d \$HOME/practice/psi ]"

# Check 10: psi_check.sh exists
check "psi_check.sh exists" \
  "[ -f \$HOME/practice/psi/psi_check.sh ]"

# Check 11: psi_check.sh references /proc/pressure files
check "psi_check.sh references /proc/pressure" \
  "grep -q '/proc/pressure' \$HOME/practice/psi/psi_check.sh"

# Check 12: psi_check.sh checks all three resources
check "psi_check.sh checks cpu, memory, and io" \
  "grep -q 'cpu' \$HOME/practice/psi/psi_check.sh && grep -q 'memory' \$HOME/practice/psi/psi_check.sh && grep -q 'io' \$HOME/practice/psi/psi_check.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
