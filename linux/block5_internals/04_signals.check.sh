#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: kill command is available
check "kill command is available" \
  "command -v kill > /dev/null 2>&1"

# Check 2: SIGTERM is signal 15
check "SIGTERM is signal 15" \
  "kill -l TERM 2>/dev/null | grep -qE '^15$' || kill -l | grep -qE '15[[:space:]]*TERM'"

# Check 3: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 4: signal_trap.sh exists
check "~/practice/signal_trap.sh exists" \
  "[ -f \$HOME/practice/signal_trap.sh ]"

# Check 5: signal_trap.sh is executable
check "signal_trap.sh is executable" \
  "[ -x \$HOME/practice/signal_trap.sh ]"

# Check 6: signal_trap.sh contains a trap statement
check "signal_trap.sh contains a trap statement" \
  "grep -q 'trap' \$HOME/practice/signal_trap.sh"

# Check 7: signal_trap.sh contains SIGTERM or TERM
check "signal_trap.sh traps SIGTERM or INT" \
  "grep -qE 'trap.*SIG(TERM|INT)|trap.*TERM|trap.*INT' \$HOME/practice/signal_trap.sh"

# Check 8: /proc/self/status has signal info
check "/proc/self/status has signal mask fields" \
  "grep -q SigBlk /proc/self/status"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
