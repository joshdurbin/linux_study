# Prometheus — Practical Monitoring

Block11/02 covered monitoring theory. This lesson is hands-on Prometheus: metric types, PromQL queries, writing exporters, and alerting rules.

## The Prometheus Data Model

Every metric in Prometheus is identified by a **metric name** plus zero or more **labels** (key-value pairs). Each unique combination of name + label set is a **time series**.

```
http_requests_total{method="GET", status="200", handler="/api/users"}
                ↑                    ↑ labels                        ↑ value: 15234
      metric name
```

### Naming Conventions

```
<namespace>_<subsystem>_<name>_<unit>
node_cpu_seconds_total
http_requests_total
process_resident_memory_bytes
go_gc_duration_seconds
```

## The Four Metric Types

### 1. Counter

Monotonically increasing. Only resets to zero when the process restarts.

```
http_requests_total{method="POST"} 42
```

**Use for:** Request counts, error counts, bytes sent.
**Never use for:** Values that can go down.

### 2. Gauge

A value that can go up or down — a snapshot at a point in time.

```
node_memory_MemFree_bytes 2147483648
go_goroutines 42
```

**Use for:** Memory usage, queue depth, temperature, active connections.

### 3. Histogram

Samples observations into configurable buckets. Enables percentile queries.

```
http_request_duration_seconds_bucket{le="0.1"}  1523   ← requests < 100ms
http_request_duration_seconds_bucket{le="0.5"}  1899   ← requests < 500ms
http_request_duration_seconds_bucket{le="+Inf"} 2000   ← all requests
http_request_duration_seconds_sum           342.5       ← total duration
http_request_duration_seconds_count          2000       ← total count
```

**Use for:** Request duration, response sizes.
**Limitation:** Bucket boundaries are fixed at instrument time. Choose them around your SLOs.

### 4. Summary

Calculates quantiles client-side. Less flexible than histograms for aggregation.

```
rpc_duration_seconds{quantile="0.5"}  0.0012
rpc_duration_seconds{quantile="0.9"}  0.0250
rpc_duration_seconds{quantile="0.99"} 0.1200
```

**Use histogram over summary** unless you can't tolerate the cross-instance aggregation limitation.

## The /metrics Endpoint

Prometheus scrapes targets via HTTP GET to `/metrics`. The format is plain text:

```bash
# Fetch metrics from any Prometheus-instrumented service
curl -s http://localhost:9090/metrics | head -30

# Fetch node_exporter metrics (if running)
curl -s http://localhost:9100/metrics | grep -E "^node_cpu_seconds|^node_memory"

# Check the format of a metrics file
curl -s http://localhost:9090/metrics | grep -E "^#|^http"
# HELP http_requests_total Number of HTTP requests
# TYPE http_requests_total counter
# http_requests_total{code="200",method="GET"} 1234
```

## PromQL — Prometheus Query Language

### Instant Vectors

```promql
# All time series for a metric
http_requests_total

# Filter by label
http_requests_total{method="GET"}
http_requests_total{method=~"GET|POST"}        # regex match
http_requests_total{status!="200"}             # not equal
http_requests_total{handler=~"/api/.*"}        # regex prefix
```

### Range Vectors and Functions

```promql
# Rate of increase over 5 minutes (use rate() for counters)
rate(http_requests_total[5m])

# Smoothed rate (less spiky than rate())
irate(http_requests_total[5m])

# Total increase over 1 hour
increase(http_requests_total[1h])

# Gauge changes
delta(node_memory_MemFree_bytes[10m])    # gauge delta over 10m
deriv(process_resident_memory_bytes[5m]) # rate of change (slope)
```

### Aggregation

```promql
# Sum across all instances (sum by label)
sum(rate(http_requests_total[5m])) by (method)

# Average
avg(go_goroutines) by (job)

# Top 5 busiest instances
topk(5, rate(http_requests_total[5m]))

# Percentiles from a histogram
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

### The Four Golden Signals in PromQL

```promql
# Latency: p99 request duration
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Traffic: requests per second
sum(rate(http_requests_total[5m]))

# Errors: error rate
sum(rate(http_requests_total{status=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))

# Saturation: CPU utilization
1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))
```

## Writing an Alerting Rule

Alerting rules evaluate PromQL expressions and fire when the condition is true for a duration:

```yaml
# /etc/prometheus/rules/sre_alerts.yml
groups:
- name: sre_alerts
  rules:
  - alert: HighErrorRate
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m]))
      / sum(rate(http_requests_total[5m])) > 0.01
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Error rate above 1% for 5 minutes"
      description: "Current error rate: {{ $value | humanizePercentage }}"

  - alert: HighLatency
    expr: |
      histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 1.0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "p99 latency above 1 second"

  - alert: NodeMemoryPressure
    expr: |
      node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
    for: 10m
    labels:
      severity: critical
    annotations:
      summary: "Less than 10% memory available on {{ $labels.instance }}"
```

## promtool — Validate Configs and Query

```bash
# Validate a Prometheus config file
promtool check config /etc/prometheus/prometheus.yml

# Validate alerting rules
promtool check rules /etc/prometheus/rules/sre_alerts.yml

# Query Prometheus API directly (curl from block2/03)
curl -s 'http://localhost:9090/api/v1/query?query=up' | python3 -m json.tool

# Range query
curl -s 'http://localhost:9090/api/v1/query_range?query=rate(http_requests_total[5m])&start=2024-01-01T00:00:00Z&end=2024-01-01T01:00:00Z&step=60s'
```

## Writing a Minimal Metrics Exporter

Any HTTP server that serves the Prometheus text format is an exporter:

```bash
# Minimal shell exporter — serves custom metrics via netcat
cat > /tmp/metrics_server.sh << 'EOF'
#!/bin/bash
while true; do
    LOAD=$(awk '{print $1}' /proc/loadavg)
    MEM_FREE=$(awk '/MemFree/{print $2}' /proc/meminfo)
    UPTIME_SECS=$(awk '{print int($1)}' /proc/uptime)

    RESPONSE="# HELP shell_load_average 1-minute load average
# TYPE shell_load_average gauge
shell_load_average $LOAD
# HELP shell_memory_free_bytes Free memory in bytes
# TYPE shell_memory_free_bytes gauge
shell_memory_free_bytes $((MEM_FREE * 1024))
# HELP shell_uptime_seconds_total Uptime in seconds
# TYPE shell_uptime_seconds_total counter
shell_uptime_seconds_total $UPTIME_SECS"

    LENGTH=${#RESPONSE}
    printf "HTTP/1.1 200 OK\r\nContent-Type: text/plain; version=0.0.4\r\nContent-Length: $LENGTH\r\n\r\n$RESPONSE" | nc -l -p 9101 -q 1 2>/dev/null
done
EOF
chmod +x /tmp/metrics_server.sh
```
