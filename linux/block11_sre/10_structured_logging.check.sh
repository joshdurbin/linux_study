#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: jq is available (from block4/04)
check "jq is available" \
  "command -v jq > /dev/null 2>&1"

# Check 2: journalctl is available (from block2/06)
check "journalctl is available" \
  "command -v journalctl > /dev/null 2>&1"

# Check 3: journalctl -o json produces valid JSON
check "journalctl -o json produces parseable JSON" \
  "journalctl -n 1 -o json 2>/dev/null | jq '.' > /dev/null 2>&1"

# Check 4: journalctl JSON has MESSAGE field
check "journalctl JSON entries have MESSAGE field" \
  "journalctl -n 1 -o json 2>/dev/null | jq -e '.MESSAGE' > /dev/null 2>&1"

# Check 5: journalctl JSON has PRIORITY field
check "journalctl JSON entries have PRIORITY field" \
  "journalctl -n 1 -o json 2>/dev/null | jq -e '.PRIORITY' > /dev/null 2>&1"

# Check 6: practice/structured_logging directory exists
check "~/practice/structured_logging directory exists" \
  "[ -d \$HOME/practice/structured_logging ]"

# Check 7: log.sh exists
check "log.sh exists" \
  "[ -f \$HOME/practice/structured_logging/log.sh ]"

# Check 8: log.sh produces valid JSON output
check "log.sh produces JSON with time, level, and msg fields" \
  "source \$HOME/practice/structured_logging/log.sh && \
   log info 'test message' 2>/dev/null | jq -e '.time and .level and .msg' > /dev/null 2>&1"

# Check 9: app.log exists
check "app.log exists" \
  "[ -f \$HOME/practice/structured_logging/app.log ]"

# Check 10: app.log is valid JSON (one object per line)
check "app.log contains valid JSON entries" \
  "head -1 \$HOME/practice/structured_logging/app.log | jq '.' > /dev/null 2>&1"

# Check 11: app.log has error entries
check "app.log has error-level entries" \
  "jq 'select(.level == \"error\")' \$HOME/practice/structured_logging/app.log | jq -e . > /dev/null 2>&1"

# Check 12: jq can filter app.log by level
check "jq can filter app.log by level=error" \
  "COUNT=\$(jq 'select(.level == \"error\")' \$HOME/practice/structured_logging/app.log | jq -s 'length'); [ \"\$COUNT\" -gt 0 ]"

# Check 13: app.log has trace_id fields
check "app.log entries have trace_id field" \
  "jq -e '.trace_id' \$HOME/practice/structured_logging/app.log > /dev/null 2>&1"

# Check 14: analyze_logs.sh exists and runs
check "analyze_logs.sh exists and runs successfully" \
  "[ -f \$HOME/practice/structured_logging/analyze_logs.sh ] && \
   bash \$HOME/practice/structured_logging/analyze_logs.sh > /dev/null 2>&1"

# Check 15: analyze_logs.sh uses jq
check "analyze_logs.sh uses jq for JSON parsing" \
  "grep -q 'jq' \$HOME/practice/structured_logging/analyze_logs.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
