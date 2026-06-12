# Exercise: Prometheus Practical

## Setup

```bash
mkdir -p ~/practice/prometheus

# Install promtool if prometheus package is available
sudo apt-get install -y prometheus-alertmanager 2>/dev/null || \
    sudo apt-get install -y prometheus 2>/dev/null || true

# Check if promtool is available
command -v promtool && promtool --version || echo "promtool not installed — using curl-based exercises"
```

## Task 1: Understand the Metrics Text Format

```bash
# Fetch metrics from a live Prometheus endpoint (if available)
if curl -s --max-time 2 http://localhost:9090/metrics > /dev/null 2>&1; then
    echo "=== Prometheus metrics sample ==="
    curl -s http://localhost:9090/metrics | grep -E "^#|^prometheus_" | head -30
elif curl -s --max-time 2 http://localhost:9100/metrics > /dev/null 2>&1; then
    echo "=== node_exporter metrics sample ==="
    curl -s http://localhost:9100/metrics | head -30
else
    echo "No local Prometheus endpoint — writing mock metrics file instead"
    cat > ~/practice/prometheus/mock_metrics.txt << 'EOF'
# HELP http_requests_total Total HTTP requests by method and status
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 15234
http_requests_total{method="POST",status="200"} 4321
http_requests_total{method="GET",status="404"} 532
http_requests_total{method="POST",status="500"} 87

# HELP http_request_duration_seconds Request duration histogram
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.05"} 12001
http_request_duration_seconds_bucket{le="0.1"}  14500
http_request_duration_seconds_bucket{le="0.5"}  18900
http_request_duration_seconds_bucket{le="1.0"}  19800
http_request_duration_seconds_bucket{le="+Inf"} 20000
http_request_duration_seconds_sum 1234.5
http_request_duration_seconds_count 20000

# HELP process_resident_memory_bytes Resident memory size
# TYPE process_resident_memory_bytes gauge
process_resident_memory_bytes 52428800

# HELP node_cpu_seconds_total Cumulative CPU seconds
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 98234.5
node_cpu_seconds_total{cpu="0",mode="user"} 1234.5
node_cpu_seconds_total{cpu="0",mode="system"} 532.1
EOF
    cat ~/practice/prometheus/mock_metrics.txt
fi
```

## Task 2: Parse Metrics with Shell Tools

Using the mock metrics (or live endpoint), practice extracting values with `grep` and `awk` (introduced in block2/02):

```bash
METRICS_FILE=~/practice/prometheus/mock_metrics.txt
[ -f "$METRICS_FILE" ] || METRICS_FILE=<(curl -s http://localhost:9090/metrics 2>/dev/null)

# Extract all counter metrics
grep -v "^#" ~/practice/prometheus/mock_metrics.txt | grep "total"

# Calculate error rate from mock data
TOTAL=$(awk '!/^#/ && /http_requests_total/ {sum+=$2} END {print sum}' ~/practice/prometheus/mock_metrics.txt)
ERRORS=$(awk '!/^#/ && /http_requests_total.*500/ {sum+=$2} END {print sum}' ~/practice/prometheus/mock_metrics.txt)
echo "Total requests: $TOTAL"
echo "5xx errors: $ERRORS"
echo "Error rate: $(awk -v t=$TOTAL -v e=$ERRORS 'BEGIN {printf "%.2f%%\n", e*100/t}')"
```

## Task 3: Write and Validate Alerting Rules

```bash
cat > ~/practice/prometheus/alerts.yml << 'EOF'
groups:
- name: practice_alerts
  rules:
  - alert: HighErrorRate
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m]))
      / sum(rate(http_requests_total[5m])) > 0.01
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Error rate above 1%"
      description: "Current rate: {{ $value | humanizePercentage }}"

  - alert: HighMemoryUsage
    expr: |
      (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > 0.90
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Memory usage above 90% on {{ $labels.instance }}"

  - alert: HighP99Latency
    expr: |
      histogram_quantile(0.99,
        rate(http_request_duration_seconds_bucket[5m])
      ) > 1.0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "p99 latency above 1 second"
EOF

# Validate the rule file
if command -v promtool > /dev/null 2>&1; then
    promtool check rules ~/practice/prometheus/alerts.yml && echo "Rules are valid"
else
    echo "Validating structure manually:"
    grep -E "alert:|expr:|for:|labels:|severity:" ~/practice/prometheus/alerts.yml
    echo "Rule file structure looks correct"
fi
```

## Task 4: Implement a Minimal Shell Metrics Exporter

```bash
cat > ~/practice/prometheus/shell_exporter.sh << 'EOF'
#!/bin/bash
# Minimal Prometheus exporter — writes metrics to stdout in text format

LOAD=$(awk '{print $1}' /proc/loadavg)
LOAD5=$(awk '{print $2}' /proc/loadavg)
LOAD15=$(awk '{print $3}' /proc/loadavg)
MEM_TOTAL=$(awk '/MemTotal/{print $2 * 1024}' /proc/meminfo)
MEM_FREE=$(awk '/MemFree/{print $2 * 1024}' /proc/meminfo)
MEM_AVAIL=$(awk '/MemAvailable/{print $2 * 1024}' /proc/meminfo)
UPTIME=$(awk '{print int($1)}' /proc/uptime)
CPU_COUNT=$(nproc)

cat << METRICS
# HELP system_load_average System load average
# TYPE system_load_average gauge
system_load_average{window="1m"} $LOAD
system_load_average{window="5m"} $LOAD5
system_load_average{window="15m"} $LOAD15

# HELP system_memory_bytes Memory size in bytes
# TYPE system_memory_bytes gauge
system_memory_bytes{type="total"} $MEM_TOTAL
system_memory_bytes{type="free"} $MEM_FREE
system_memory_bytes{type="available"} $MEM_AVAIL

# HELP system_uptime_seconds_total System uptime in seconds
# TYPE system_uptime_seconds_total counter
system_uptime_seconds_total $UPTIME

# HELP system_cpu_count Number of logical CPUs
# TYPE system_cpu_count gauge
system_cpu_count $CPU_COUNT
METRICS
EOF
chmod +x ~/practice/prometheus/shell_exporter.sh

echo "=== Exporter output ==="
bash ~/practice/prometheus/shell_exporter.sh
```

## Task 5: Write a PromQL Cheat Sheet

```bash
cat > ~/practice/prometheus/promql_cheatsheet.md << 'EOF'
# PromQL Cheat Sheet

## Selectors
metric_name                         # all series
metric{label="value"}               # exact match
metric{label=~"val.*"}              # regex match
metric{label!="value"}              # not equal

## Rate functions (for counters)
rate(counter[5m])                   # per-second rate, smoothed
irate(counter[5m])                  # instant rate (last 2 samples)
increase(counter[1h])               # total increase over time range

## Aggregations
sum(metric) by (label)
avg(metric) by (label)
max(metric) by (label)
count(metric) by (label)
topk(5, metric)
bottomk(5, metric)

## Histogram percentiles
histogram_quantile(0.99, rate(metric_bucket[5m]))

## The Four Golden Signals
# Latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Traffic (RPS)
sum(rate(http_requests_total[5m]))

# Errors (error rate)
sum(rate(http_requests_total{status=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))

# Saturation (CPU)
1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance)
EOF
cat ~/practice/prometheus/promql_cheatsheet.md
```

## Expected Outcome

- Prometheus metrics text format is understood (# HELP, # TYPE, metric lines)
- `~/practice/prometheus/mock_metrics.txt` — sample metrics file
- `~/practice/prometheus/alerts.yml` — alerting rules with valid structure
- Alert rules are validated with `promtool check rules` or manually
- `~/practice/prometheus/shell_exporter.sh` — outputs metrics in Prometheus text format
- `~/practice/prometheus/promql_cheatsheet.md` — PromQL reference
