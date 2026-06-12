#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: gdb is available
check "gdb is available" \
  "command -v gdb > /dev/null 2>&1"

# Check 2: gcc is available (from block5/20)
check "gcc is available" \
  "command -v gcc > /dev/null 2>&1"

# Check 3: strace is available (from block5/03)
check "strace is available" \
  "command -v strace > /dev/null 2>&1"

# Check 4: practice/gdb directory exists
check "~/practice/gdb directory exists" \
  "[ -d \$HOME/practice/gdb ]"

# Check 5: debug_me.c exists
check "debug_me.c exists" \
  "[ -f \$HOME/practice/gdb/debug_me.c ]"

# Check 6: debug_me binary exists with debug symbols
check "debug_me binary compiled with debug symbols" \
  "[ -f \$HOME/practice/gdb/debug_me ] && \
   readelf -S \$HOME/practice/gdb/debug_me 2>/dev/null | grep -q '\.debug_info'"

# Check 7: crash_me.c exists
check "crash_me.c exists" \
  "[ -f \$HOME/practice/gdb/crash_me.c ]"

# Check 8: crash_me binary exists
check "crash_me binary exists" \
  "[ -f \$HOME/practice/gdb/crash_me ]"

# Check 9: crash_me actually crashes (exits non-zero)
check "crash_me exits non-zero (crashes as expected)" \
  "! \$HOME/practice/gdb/crash_me > /dev/null 2>&1"

# Check 10: gdb can produce a backtrace for crash_me
check "gdb produces a backtrace for crash_me" \
  "gdb -batch -ex 'run' -ex 'backtrace' \$HOME/practice/gdb/crash_me 2>/dev/null | \
   grep -qE 'bad_function|main'"

# Check 11: gdb backtrace mentions the crash function
check "gdb backtrace identifies bad_function as crash site" \
  "gdb -batch -ex 'run' -ex 'backtrace' \$HOME/practice/gdb/crash_me 2>/dev/null | \
   grep -q 'bad_function'"

# Check 12: gdb can break on main and run debug_me
check "gdb can set breakpoint on main and run debug_me" \
  "gdb -batch -ex 'break main' -ex 'run 3' -ex 'continue' -ex 'quit' \
   \$HOME/practice/gdb/debug_me 2>/dev/null | grep -qE 'Breakpoint|factorial'"

# Check 13: inspect.gdb script exists and references break/run
check "inspect.gdb script exists" \
  "[ -f \$HOME/practice/gdb/inspect.gdb ]"

check "inspect.gdb has break and run commands" \
  "grep -q 'break' \$HOME/practice/gdb/inspect.gdb && \
   grep -q 'run' \$HOME/practice/gdb/inspect.gdb"

# Check 15: ulimit -c can be set (core dump support works)
check "ulimit -c unlimited is settable" \
  "ulimit -c unlimited && [ \"\$(ulimit -c)\" = 'unlimited' ]"

# Check 16: /proc/sys/kernel/core_pattern is readable
check "/proc/sys/kernel/core_pattern is readable" \
  "[ -r /proc/sys/kernel/core_pattern ]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
