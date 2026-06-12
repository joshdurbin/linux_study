# Monitoring and Alerting

## The Four Golden Signals

Google SRE defines four metrics that, if measured, give a complete picture of service health:

1. **Latency** — How long it takes to serve a request. Track separately for successful and failed requests. A fast error is still useful to know.

2. **Traffic** — How much demand is being placed on the system. Requests per second, messages per second, or bytes per second.

3. **Errors** — The rate of failed requests. Distinguish explicit failures (5xx), implicit failures (200 with wrong content), and policy failures (latency > SLO).

4. **Saturation** — How "full" the service is. CPU, memory, queue depth, disk I/O. Saturation predicts when you'll run out.

## USE Method (for Resources)

For every resource (CPU, memory, disk, network):
- **Utilization**: What % of time is the resource busy?
- **Saturation**: Is there work queued waiting for the resource?
- **Errors**: Are there error events from this resource?

```bash
# CPU utilization and saturation
mpstat 1
vmstat 1   # procs r column = run queue (saturation indicator)

# Memory utilization and saturation
free -m
vmstat 1   # si/so columns = swap in/out (saturation)

# Disk utilization and saturation
iostat -x 1   # %util, await (queue/saturation)
```

## RED Method (for Services)

For every service (microservice, endpoint):
- **Rate**: Requests per second
- **Errors**: Error rate (fraction)
- **Duration**: Distribution of request latencies

RED is the user-facing counterpart to USE.

## Prometheus Data Model

Prometheus is the de facto standard for metrics in cloud-native environments.

```bash
# Data types:
# Counter:    monotonically increasing (total_requests, total_errors)
# Gauge:      can go up or down (current_connections, memory_used_bytes)
# Histogram:  distribution of observations (request_duration_seconds)
# Summary:    percentile calculations (less flexible than histograms)

# PromQL examples:
# Request rate (per second, 5m window):
rate(http_requests_total[5m])

# Error rate:
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# p99 latency from histogram:
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# CPU usage per pod (Kubernetes):
rate(container_cpu_usage_seconds_total[5m])
```

## Alert Design Principles

**Symptom-based over cause-based**: Alert on what the user experiences, not the component that's failing. "High error rate on checkout" is more actionable than "MySQL replica lag > 10s".

**Alert on SLO burn rate**: If you're burning error budget faster than it refills, alert. This catches problems early regardless of cause.

```
# Multi-window burn rate alert (Google's approach):
# 5% budget burned in 1 hour → page (2% burn in 1h + 5% burn in 5min)
# 10% budget burned in 6 hours → ticket
```

**Avoid alert fatigue**:
- Every alert must be actionable
- Remove alerts that are always false positive
- Suppress dependent alerts (don't alert on 50 symptoms of one root cause)
- Use "pending" period before firing to reduce noise

## Grafana

Grafana is the standard visualization layer for Prometheus:

```bash
# Common panel types:
# Time series: latency, request rate over time
# Stat panel: current value (e.g., availability this month)
# Heatmap: latency distribution over time
# Table: top errors, slowest endpoints

# Dashboard variables: select namespace, service, time range
# Alert rules: can be defined in Grafana or Prometheus Alertmanager
```

## Key Takeaways

- Four Golden Signals: latency, traffic, errors, saturation — a complete picture of health.
- USE for resources; RED for services.
- Alert on symptoms (user-facing impact) rather than causes (component metrics).
- Alert on SLO burn rate to catch problems early, regardless of root cause.
- Alert fatigue is dangerous: a team that ignores alerts misses real incidents.
- Prometheus + Grafana is the standard cloud-native monitoring stack.
