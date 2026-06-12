# Structured Logging

Unstructured logs are text written for humans. Structured logs are key-value documents written for machines — queryable, filterable, and aggregatable without regex. This distinction determines whether your logs help you during an incident or frustrate you.

## Unstructured vs Structured

```
# Unstructured — can only search with grep
2024-03-15 14:23:01 ERROR Failed to connect to database: connection refused (host=db1, port=5432)

# Structured JSON — every field is queryable
{"time":"2024-03-15T14:23:01Z","level":"error","msg":"Failed to connect to database",
 "host":"db1","port":5432,"error":"connection refused","trace_id":"abc123","duration_ms":5003}
```

With structured logging you can ask: *show me all errors where duration_ms > 1000 grouped by host* — instantly, without fragile regex.

## journald — Linux's Structured Logger

`journald` (part of systemd — block2/06) stores logs as structured binary data. Every log entry is a key-value record that you can query without parsing.

### Built-in Fields

| Field | Meaning |
|-------|---------|
| `MESSAGE` | The log text |
| `PRIORITY` | Syslog priority (0=emerg, 7=debug) |
| `_PID` | PID of logging process |
| `_UID` | UID of logging process |
| `_COMM` | Process name |
| `_EXE` | Executable path |
| `SYSLOG_IDENTIFIER` | Unit name or service name |
| `_SYSTEMD_UNIT` | Systemd unit |
| `_HOSTNAME` | Hostname |
| `_TRANSPORT` | How the message arrived (journal, syslog, kernel) |

```bash
# Read logs in JSON format (jq from block4/04)
journalctl -o json -n 5 | jq .

# Filter by field value
journalctl _PID=1234
journalctl _COMM=nginx
journalctl _SYSTEMD_UNIT=sshd.service

# Show only specific fields
journalctl -o json -n 20 | jq '{time: .REALTIME_TIMESTAMP, msg: .MESSAGE, pid: ._PID}'

# Filter on priority (err and above)
journalctl -p err -n 20

# Query by custom field (if the app logs it)
journalctl TRACE_ID=abc123
```

### Writing to journald with Custom Fields

Applications can write structured entries directly to journald using the `sd_journal_send` C API or via `systemd-cat`:

```bash
# Write a structured log entry from the command line
echo "MESSAGE=Deployment completed DEPLOY_VERSION=v1.2.3 ENVIRONMENT=production" \
    | systemd-cat -t myapp -p info

# Or with systemd-cat piping
echo "health check passed" | systemd-cat -t myapp -p notice

# Read it back with custom field
journalctl -t myapp -n 5 -o json | jq '{msg: .MESSAGE}'
```

## JSON Logging Best Practices

### Required Fields

Every structured log entry should have:

```json
{
  "time":     "2024-03-15T14:23:01.123Z",   // ISO 8601, always UTC
  "level":    "error",                        // debug/info/warn/error/critical
  "msg":      "connection failed",            // human-readable summary
  "service":  "auth-api",                    // which service
  "trace_id": "4bf92f3577b34da6",            // distributed trace ID (if available)
  "span_id":  "00f067aa0ba902b7"             // span within trace
}
```

### Context Fields (add per-operation)

```json
{
  "user_id":     "u-123456",
  "request_id":  "req-abc",
  "method":      "POST",
  "path":        "/api/checkout",
  "status":      500,
  "duration_ms": 1234,
  "error":       "upstream timeout",
  "retries":     2
}
```

### Log Levels as Numbers

```bash
# Consistent numeric levels (easier to filter with >=)
# 10 = debug
# 20 = info
# 30 = warn
# 40 = error
# 50 = critical
```

## Parsing Structured Logs with jq

`jq` (block4/04) is the primary tool for working with JSON logs:

```bash
# Pretty-print recent journald logs as JSON
journalctl -n 20 -o json | jq '.'

# Extract specific fields
journalctl -n 50 -o json | jq -r '[.REALTIME_TIMESTAMP, ._COMM, .MESSAGE] | @tsv'

# Filter: only error-level entries
journalctl -n 100 -o json | jq 'select(.PRIORITY <= "3")'

# Count by process name (top talkers)
journalctl -n 1000 -o json | jq -r '._COMM' | sort | uniq -c | sort -rn | head -10

# Extract fields from JSON application logs (if app logs JSON to stdout)
journalctl -u myapp -n 100 -o json \
    | jq -r '.MESSAGE' \
    | jq -r 'select(.level == "error") | [.time, .msg, .error] | @tsv'
```

## Trace IDs and Log Correlation

Distributed tracing connects log entries across services using **trace IDs**:

```
Request → Service A (trace_id=abc123) → Service B (trace_id=abc123) → Database
```

Every log entry from every service involved in handling that request carries the same `trace_id`. You can reconstruct the full request path by filtering logs for a single trace ID.

```bash
# Find all log entries for a specific request
journalctl -o json | jq -r 'select(.trace_id == "abc123")' 2>/dev/null

# With structured JSON logs in a file
grep '"trace_id":"abc123"' /var/log/app.json | jq '.'
```

## Practical Logging Patterns

```bash
# Shell script structured logging function
log() {
    local level=$1; shift
    local msg=$1; shift
    printf '{"time":"%s","level":"%s","msg":"%s"' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$msg"
    # Additional key=value pairs become JSON fields
    while [ $# -gt 0 ]; do
        key=$(echo "$1" | cut -d= -f1)
        val=$(echo "$1" | cut -d= -f2-)
        printf ',%s":"%s"' "\"$key" "$val"
        shift
    done
    printf '}\n'
}

log info "deployment started" version=v1.2.3 environment=production
log error "health check failed" host=db1 attempts=3 duration_ms=5023
```

## Structured Log Aggregation

At scale, structured logs flow to an aggregation backend:

| Tool | Log Format | Query Language |
|------|-----------|---------------|
| Elasticsearch + Kibana | JSON | KQL, Lucene |
| Loki + Grafana | Any (labels-based) | LogQL |
| Splunk | Any | SPL |
| CloudWatch Logs | JSON | CloudWatch Insights |

**Loki** is the Prometheus-adjacent choice for Kubernetes/cloud environments — it indexes labels (like Prometheus) rather than the full log content, keeping costs low.

```bash
# LogQL (Grafana Loki) examples — conceptually similar to PromQL:
{service="auth-api"} | json | level="error"
{service="auth-api"} | json | duration_ms > 1000 | line_format "{{.msg}}"
rate({service="auth-api"} | json | level="error" [5m])
```
