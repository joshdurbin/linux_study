#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: fio is installed
check "fio is installed" \
  "command -v fio > /dev/null 2>&1"

# Check 2: fio --version works
check "fio --version reports a version string" \
  "fio --version 2>&1 | grep -qi 'fio'"

# Check 3: practice/fio directory exists
check "~/practice/fio directory exists" \
  "[ -d \$HOME/practice/fio ]"

# Check 4: fio job file exists
check "rand_read.fio job file exists" \
  "[ -f \$HOME/practice/fio/rand_read.fio ]"

# Check 5: job file references fio parameters (rw= and size=)
check "rand_read.fio contains rw= and size= parameters" \
  "grep -q 'rw=' \$HOME/practice/fio/rand_read.fio && grep -q 'size=' \$HOME/practice/fio/rand_read.fio"

# Check 6: bench_storage.sh exists
check "bench_storage.sh exists" \
  "[ -f \$HOME/practice/fio/bench_storage.sh ]"

# Check 7: bench_storage.sh references fio
check "bench_storage.sh invokes fio" \
  "grep -q 'fio' \$HOME/practice/fio/bench_storage.sh"

# Check 8: bench_storage.sh references key patterns (read and write)
check "bench_storage.sh covers read and write patterns" \
  "grep -q 'read' \$HOME/practice/fio/bench_storage.sh && grep -q 'write' \$HOME/practice/fio/bench_storage.sh"

# Check 9: bench_storage.sh is executable
check "bench_storage.sh is executable" \
  "[ -x \$HOME/practice/fio/bench_storage.sh ]"

# Check 10: fio can actually run a short sequential test (5s)
check "fio can run a 5-second sequential read test" \
  "fio --name=check-run \
       --ioengine=sync \
       --rw=read \
       --bs=512k \
       --size=32m \
       --numjobs=1 \
       --iodepth=1 \
       --runtime=5 \
       --time_based \
       --filename=/tmp/fio_check_run \
       --group_reporting \
       > /dev/null 2>&1; EC=\$?; rm -f /tmp/fio_check_run; [ \$EC -eq 0 ]"

# Check 11: fio can run from the job file
check "fio job file can be executed by fio" \
  "fio \$HOME/practice/fio/rand_read.fio > /dev/null 2>&1"

# Check 12: bench_storage.sh runs without crashing
check "bench_storage.sh completes successfully" \
  "\$HOME/practice/fio/bench_storage.sh /tmp > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
