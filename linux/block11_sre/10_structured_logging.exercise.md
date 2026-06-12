# Exercise: Structured Logging

## Setup

```bash
mkdir -p ~/practice/structured_logging
```

## Task 1: Read journald Logs as JSON

```bash
# Read recent journal entries as JSON
journalctl -n 5 -o json 2>/dev/null | jq '.' | head -60 || \
    journalctl -n 5 -o json 2>/dev/null | head -20

# Extract just the key fields using jq (from block4/04)
journalctl -n 10 -o json 2>/dev/null | \
    jq -r '[.PRIORITY, ._COMM // "unknown", .MESSAGE] | @tsv' | head -10
```

## Task 2: Filter journald by Field

```bash
# Filter by priority (3=err, 4=warning, 6=info, 7=debug)
echo "=== Error and critical messages ==="
journalctl -p err -n 10 --no-pager

echo ""
echo "=== Kernel messages ==="
journalctl _TRANSPORT=kernel -n 5 --no-pager

echo ""
echo "=== Process by name ==="
journalctl _COMM=bash -n 5 --no-pager 2>/dev/null || echo "(no bash log entries)"
```

## Task 3: JSON Processing with jq

```bash
# Top processes by log volume
echo "=== Top log producers (last 500 entries) ==="
journalctl -n 500 -o json 2>/dev/null | \
    jq -r '._COMM // "unknown"' | \
    sort | uniq -c | sort -rn | head -10

# Priority distribution
echo ""
echo "=== Log priority distribution ==="
journalctl -n 500 -o json 2>/dev/null | \
    jq -r '.PRIORITY' | \
    sort | uniq -c | sort -rn | \
    awk '{
        p=$2
        if (p=="0") name="emerg"
        else if (p=="1") name="alert"
        else if (p=="2") name="crit"
        else if (p=="3") name="err"
        else if (p=="4") name="warning"
        else if (p=="5") name="notice"
        else if (p=="6") name="info"
        else if (p=="7") name="debug"
        else name="p"p
        print $1, name
    }'
```

## Task 4: Write a Structured Log Function

```bash
cat > ~/practice/structured_logging/log.sh << 'EOF'
#!/bin/bash
# Structured logging functions for shell scripts

LOG_SERVICE="${LOG_SERVICE:-shell-script}"

log() {
    local level="$1"; shift
    local msg="$1"; shift

    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Build JSON output
    printf '{"time":"%s","level":"%s","service":"%s","msg":"%s"' \
        "$timestamp" "$level" "$LOG_SERVICE" "$msg"

    # Additional key=value pairs
    while [ "$#" -gt 0 ]; do
        local kv="$1"; shift
        local key="${kv%%=*}"
        local val="${kv#*=}"
        printf ',"%s":"%s"' "$key" "$val"
    done

    printf '}\n'
}

log_info()  { log "info"  "$@"; }
log_warn()  { log "warn"  "$@"; }
log_error() { log "error" "$@" >&2; }
EOF

# Test the logging functions
source ~/practice/structured_logging/log.sh

LOG_SERVICE="my-deploy-script" log_info "Deployment started" \
    version=v1.2.3 environment=production target=web-01

LOG_SERVICE="my-deploy-script" log_warn "Health check slow" \
    host=web-01 duration_ms=450 threshold_ms=200

LOG_SERVICE="my-deploy-script" log_error "Connection failed" \
    host=db1 port=5432 error="connection refused" attempt=3
```

## Task 5: Parse a JSON Log File

```bash
# Create a sample structured log file
cat > ~/practice/structured_logging/app.log << 'EOF'
{"time":"2024-03-15T10:00:01Z","level":"info","service":"api","msg":"Request received","method":"GET","path":"/health","trace_id":"abc123","duration_ms":2}
{"time":"2024-03-15T10:00:02Z","level":"info","service":"api","msg":"Request received","method":"POST","path":"/api/users","trace_id":"def456","duration_ms":145}
{"time":"2024-03-15T10:00:03Z","level":"error","service":"api","msg":"Database error","trace_id":"def456","error":"connection refused","host":"db1","duration_ms":5001}
{"time":"2024-03-15T10:00:04Z","level":"warn","service":"api","msg":"Retry succeeded","trace_id":"def456","attempt":2,"duration_ms":230}
{"time":"2024-03-15T10:00:05Z","level":"info","service":"api","msg":"Request received","method":"GET","path":"/api/users/123","trace_id":"ghi789","duration_ms":89}
{"time":"2024-03-15T10:00:06Z","level":"error","service":"api","msg":"Upstream timeout","trace_id":"ghi789","upstream":"cache","duration_ms":3000}
EOF

echo "=== All error entries ==="
jq 'select(.level == "error")' ~/practice/structured_logging/app.log

echo ""
echo "=== Slow requests (> 1 second) ==="
jq 'select(.duration_ms > 1000) | {time, level, msg, duration_ms, trace_id}' \
    ~/practice/structured_logging/app.log

echo ""
echo "=== Trace the failed request def456 ==="
jq 'select(.trace_id == "def456") | [.time, .level, .msg] | @tsv' \
    ~/practice/structured_logging/app.log -r
```

## Task 6: Write to journald with Custom Fields

```bash
# Write a structured entry to journald
echo "Structured logging exercise complete" | systemd-cat -t practice-logger -p info 2>/dev/null || true

# Write with custom identifier
systemd-cat -t practice-exercise -p notice << 'EOF' 2>/dev/null
Exercise completed successfully
EOF

# Read it back
journalctl -t practice-logger -n 3 --no-pager -o json 2>/dev/null | \
    jq -r '[.time, .MESSAGE] | @tsv' 2>/dev/null || echo "journald write completed"
```

## Task 7: Write a Log Analysis Script

```bash
cat > ~/practice/structured_logging/analyze_logs.sh << 'EOF'
#!/bin/bash
# Analyze structured JSON logs from a file
LOG_FILE=${1:-~/practice/structured_logging/app.log}

echo "=== Log Analysis: $LOG_FILE ==="
echo ""

# Total entries
TOTAL=$(wc -l < "$LOG_FILE")
echo "Total entries: $TOTAL"

# By level
echo ""
echo "By level:"
jq -r '.level' "$LOG_FILE" | sort | uniq -c | sort -rn

# Error rate
ERRORS=$(jq 'select(.level == "error")' "$LOG_FILE" | jq -s 'length')
echo ""
echo "Errors: $ERRORS / $TOTAL ($(awk -v e=$ERRORS -v t=$TOTAL 'BEGIN {printf "%.1f%%", e*100/t}'))"

# Slowest requests
echo ""
echo "Slowest operations (top 3):"
jq -r '[.duration_ms, .msg, .trace_id // "none"] | @tsv' "$LOG_FILE" \
    | sort -rn | head -3 | column -t
EOF
chmod +x ~/practice/structured_logging/analyze_logs.sh
bash ~/practice/structured_logging/analyze_logs.sh
```

## Expected Outcome

- `journalctl -o json` outputs structured journal entries
- `jq` parses journal JSON to extract fields and count by priority/process
- `~/practice/structured_logging/log.sh` — structured logging library for shell scripts
- `~/practice/structured_logging/app.log` — sample JSON log file
- `jq select(.level == "error")` filters log file by level
- `jq select(.trace_id == "def456")` traces a single request across entries
- `analyze_logs.sh` reports error rate and slowest operations from a JSON log file
