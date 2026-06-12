#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: mkfifo command is available
check "mkfifo command is available" \
  "command -v mkfifo > /dev/null 2>&1"

# Check 2: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 3: myfifo exists
check "~/practice/myfifo exists" \
  "[ -e \$HOME/practice/myfifo ]"

# Check 4: myfifo is a named pipe
check "~/practice/myfifo is a named pipe (FIFO)" \
  "[ -p \$HOME/practice/myfifo ]"

# Check 5: /dev/shm exists and is writable
check "/dev/shm exists and is writable" \
  "[ -d /dev/shm ] && [ -w /dev/shm ]"

# Check 6: ipcs command is available
check "ipcs command is available" \
  "command -v ipcs > /dev/null 2>&1"

# Check 7: ipcs runs without error
check "ipcs -m runs successfully" \
  "ipcs -m > /dev/null 2>&1"

# Check 8: pipe-max-size is readable
check "/proc/sys/fs/pipe-max-size is readable" \
  "[ -r /proc/sys/fs/pipe-max-size ]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
