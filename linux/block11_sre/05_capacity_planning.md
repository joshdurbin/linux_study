# Capacity Planning

## What Is Capacity Planning?

**Capacity planning** is the process of forecasting future resource needs and provisioning infrastructure before demand exceeds supply. Done well, it prevents outages caused by resource exhaustion and avoids over-provisioning that wastes money.

The basic workflow:
1. Measure current resource utilization
2. Model growth trajectory
3. Project when current capacity will be exhausted
4. Provision new capacity before that point (with lead time)

## Key Metrics to Track

| Resource | Metric | Tool |
|----------|--------|------|
| CPU | % utilization, run queue, throttled time | `mpstat`, `top`, Prometheus |
| Memory | used/available, swap usage, OOM kills | `free`, `/proc/meminfo` |
| Storage | disk % used, IOPS, write throughput | `df`, `iostat` |
| Network | bytes in/out, packet drops, retransmits | `sar -n DEV`, `ss` |
| Application | requests/sec, queue depth, p99 latency | APM, Prometheus |

```bash
# Current resource snapshot
mpstat 1 5                        # CPU utilization
free -m                           # memory
df -h                             # disk
iostat -x 1 5                     # disk I/O
sar -n DEV 1 5                    # network
```

## Latency Percentiles: p50, p95, p99

Never plan capacity around averages alone. Use percentiles:

- **p50 (median)**: the typical case — half of requests are faster
- **p95**: 95% of requests complete at or below this time
- **p99**: the worst 1% — these are the users having a bad experience

A service with p50=50ms and p99=2000ms has a serious tail latency problem. Plan for the p99.

```bash
# Calculate percentiles from a log of response times (one per line):
sort -n response_times.txt | awk '
  BEGIN { total = 0 }
  { lines[NR] = $1; total++ }
  END {
    p50 = lines[int(total * 0.50)]
    p95 = lines[int(total * 0.95)]
    p99 = lines[int(total * 0.99)]
    printf "p50=%dms p95=%dms p99=%dms\n", p50, p95, p99
  }'
```

## Load Testing

Load testing establishes the baseline before production load increases:

```bash
# Apache Bench: simple HTTP load test
ab -n 10000 -c 50 https://api.example.com/orders/

# vegeta: more flexible, reads targets from file
echo "GET https://api.example.com/orders/" | \
  vegeta attack -rate=200 -duration=60s | \
  vegeta report

# k6: JavaScript-based load testing
k6 run --vus 50 --duration 30s load_test.js
```

## Back-of-Envelope Calculations

### Memory per Request
```
Web server with 200 concurrent connections:
  Each request holds 4MB in memory during processing
  Peak memory for requests = 200 × 4MB = 800MB
  Add OS/runtime overhead: 1.5× = 1.2GB
  Reserve headroom: 1.2GB / 0.8 = 1.5GB minimum
```

### Storage Growth
```
Log volume: 5GB/day
Retention: 30 days
Storage needed: 150GB + 20% headroom = 180GB

Database growth: 10GB/month
Time to fill 500GB: 50 months ≈ 4 years
Alert threshold: 80% full = 400GB, add more storage at ~3.5 years
```

### Requests Per Second Capacity
```
Single server handles 500 req/s at 80% CPU
Target headroom: 30% (run at 70% peak utilization)
Usable capacity: 500 × 0.70 = 350 req/s per server
For 1000 req/s: ceil(1000 / 350) = 3 servers minimum
Add N+1 redundancy: 4 servers
```

## Provisioning Headroom

Industry guidelines:
- **CPU**: sustain ≤ 70% utilization at peak (30% headroom)
- **Memory**: sustain ≤ 80% utilization (20% headroom)
- **Disk**: alert at 80%, add capacity before 90%
- **Network**: sustain ≤ 60% of link capacity (bursty traffic needs more headroom)

## Key Takeaways

- Capacity planning prevents outages from resource exhaustion and avoids over-provisioning.
- Track CPU, memory, storage, network, and application-level metrics.
- Plan for p99 latency, not just averages — the tail is where users suffer.
- Load test to find the breaking point before production traffic does.
- Maintain 20-30% headroom for unexpected spikes and organic growth.
- Model growth: if you grow 10% per month, current capacity runs out in log(2)/log(1.1) ≈ 7 months.
