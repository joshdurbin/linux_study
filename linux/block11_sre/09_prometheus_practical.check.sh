#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: curl is available (from block2/03)
check "curl is available" \
  "command -v curl > /dev/null 2>&1"

# Check 2: practice/prometheus directory exists
check "~/practice/prometheus directory exists" \
  "[ -d \$HOME/practice/prometheus ]"

# Check 3: mock_metrics.txt exists
check "mock_metrics.txt exists" \
  "[ -f \$HOME/practice/prometheus/mock_metrics.txt ]"

# Check 4: mock_metrics.txt has proper Prometheus text format headers
check "mock_metrics.txt has HELP lines" \
  "grep -q '^# HELP' \$HOME/practice/prometheus/mock_metrics.txt"

check "mock_metrics.txt has TYPE lines" \
  "grep -q '^# TYPE' \$HOME/practice/prometheus/mock_metrics.txt"

# Check 6: mock_metrics.txt has counter, gauge, and histogram types
check "mock_metrics.txt includes counter type" \
  "grep -q 'counter' \$HOME/practice/prometheus/mock_metrics.txt"

check "mock_metrics.txt includes gauge type" \
  "grep -q 'gauge' \$HOME/practice/prometheus/mock_metrics.txt"

check "mock_metrics.txt includes histogram type" \
  "grep -q 'histogram' \$HOME/practice/prometheus/mock_metrics.txt"

# Check 9: alerts.yml exists
check "alerts.yml exists" \
  "[ -f \$HOME/practice/prometheus/alerts.yml ]"

# Check 10: alerts.yml has alert rules
check "alerts.yml has at least one alert" \
  "grep -q 'alert:' \$HOME/practice/prometheus/alerts.yml"

# Check 11: alerts.yml has expr, for, labels, annotations
check "alerts.yml has expr, for, severity" \
  "grep -q 'expr:' \$HOME/practice/prometheus/alerts.yml && \
   grep -q 'for:' \$HOME/practice/prometheus/alerts.yml && \
   grep -q 'severity' \$HOME/practice/prometheus/alerts.yml"

# Check 12: shell_exporter.sh exists and is executable
check "shell_exporter.sh exists and is executable" \
  "[ -x \$HOME/practice/prometheus/shell_exporter.sh ]"

# Check 13: shell_exporter.sh outputs valid Prometheus format
check "shell_exporter.sh outputs HELP and TYPE lines" \
  "bash \$HOME/practice/prometheus/shell_exporter.sh 2>/dev/null | grep -q '^# HELP' && \
   bash \$HOME/practice/prometheus/shell_exporter.sh 2>/dev/null | grep -q '^# TYPE'"

# Check 14: shell_exporter.sh reads /proc/loadavg
check "shell_exporter.sh reads from /proc" \
  "grep -q '/proc' \$HOME/practice/prometheus/shell_exporter.sh"

# Check 15: promql_cheatsheet.md exists
check "promql_cheatsheet.md exists" \
  "[ -f \$HOME/practice/prometheus/promql_cheatsheet.md ]"

# Check 16: cheatsheet mentions rate() and histogram_quantile
check "promql_cheatsheet.md covers rate() and histogram_quantile()" \
  "grep -q 'rate(' \$HOME/practice/prometheus/promql_cheatsheet.md && \
   grep -q 'histogram_quantile' \$HOME/practice/prometheus/promql_cheatsheet.md"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
