# Exercise: Monitoring and Alerting

Complete the following tasks. Save your notes to `~/practice/monitoring_notes.txt`.

## Task 1 — Write a Monitoring Strategy Using the Four Golden Signals

```bash
mkdir -p ~/practice
cat > ~/practice/monitoring_notes.txt << 'EOF'
Monitoring and Alerting Notes
==============================

Monitoring Strategy for "OrdersAPI" Web Service
-------------------------------------------------
Using the Four Golden Signals:

1. LATENCY
   What to measure: p50, p95, p99 of HTTP request duration
   SLO target: p99 < 300ms
   Tool: Prometheus histogram_quantile()
   PromQL: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
   Alert: page if p99 > 300ms for > 5 minutes

2. TRAFFIC
   What to measure: requests per second to each endpoint
   Baseline: ~500 req/s; alert if drops below 50 req/s (suggests upstream problem)
   PromQL: rate(http_requests_total[5m])
   Alert: ticket if traffic drops > 80% from rolling average

3. ERRORS
   What to measure: rate of 5xx responses
   SLO target: error rate < 0.1%
   PromQL: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
   Alert: page if error rate > 1% for 2 minutes; ticket if > 0.1% for 10 minutes

4. SATURATION
   What to measure: CPU, memory, DB connection pool usage
   Alert thresholds:
     CPU: page if sustained > 90% for 5 minutes
     Memory: page if > 85% for 10 minutes
     DB connections: alert if connection pool > 80% full
   PromQL (CPU): avg(rate(container_cpu_usage_seconds_total[5m])) by (pod)
EOF
```

## Task 2 — Apply USE Method to a Resource

```bash
cat >> ~/practice/monitoring_notes.txt << 'EOF'

USE Method Applied to CPU
--------------------------
Utilization:
  mpstat 1 5           # average CPU % across 5 seconds
  top -bn1 | head -5   # current CPU utilization

Saturation (run queue = work waiting for CPU):
  vmstat 1 5           # column "r" = run queue length
  Rule of thumb: if r > number of CPUs, system is CPU saturated

Errors:
  dmesg | grep -i "hardware error\|mce"   # machine check exceptions
  Usually 0; hardware errors are rare

If CPU utilization > 80% sustained: scale out or optimize hot path
If run queue > 2x CPU count: immediate action needed
EOF
```

## Task 3 — Document Alert Design Rules

```bash
cat >> ~/practice/monitoring_notes.txt << 'EOF'

Alert Design Principles
------------------------
Good alert criteria:
  - Alerts on symptoms (user-facing impact), not causes
  - Every alert is actionable — if you can't act on it, remove it
  - Alerts have clear remediation steps (linked runbook)
  - Pending period of 2-5 min to filter transient spikes

Alert severity levels:
  PAGE (wake someone up):
    - Error rate > 5x SLO for > 2 min
    - Service completely unavailable
    - SLO burn rate consuming > 5% budget/hour
  TICKET (fix during business hours):
    - Slow SLO burn (trending toward miss this week)
    - Saturation approaching threshold
    - Non-critical dependency degraded

Alert fatigue warning signs:
  - On-call engineers acknowledge alerts without reading them
  - Same alert fires > 3x per week (either fix it or remove it)
  - Alerts fire during known maintenance windows (add silences)
  - Multiple alerts for the same root cause (add inhibit rules)
EOF
```

## Task 4 — List Key PromQL Patterns

```bash
cat >> ~/practice/monitoring_notes.txt << 'EOF'

Key PromQL Patterns
--------------------
# Request rate (per second, 5m window)
rate(http_requests_total[5m])

# Error ratio
rate(http_requests_total{status=~"5.."}[5m])
  / rate(http_requests_total[5m])

# p99 latency from histogram
histogram_quantile(0.99,
  rate(http_request_duration_seconds_bucket[5m]))

# Availability (complement of error rate)
1 - (rate(http_requests_total{status=~"5.."}[30d])
     / rate(http_requests_total[30d]))

# Error budget remaining (for 99.9% SLO over 30 days)
1 - (
  (1 - sum(rate(http_requests_total{status!~"5.."}[30d])) /
       sum(rate(http_requests_total[30d])))
  / (1 - 0.999)
)
EOF
```
