# Exercise: Capacity Planning

Complete the following tasks. Save your capacity plan to `~/practice/capacity_plan.txt`.

## Task 1 — Write a Capacity Planning Worksheet

Create a capacity plan for a web service handling 1000 req/s:

```bash
mkdir -p ~/practice
cat > ~/practice/capacity_plan.txt << 'EOF'
Capacity Planning Worksheet
============================
Service: OrdersAPI
Current traffic: 1,000 req/s (peak, business hours)
Growth rate: 15% per month (based on last 6 months)
Current infrastructure: 4 app servers, 1 DB primary + 1 replica

=== CURRENT RESOURCE UTILIZATION ===

CPU:
  Current peak: 65% (4 cores per server)
  Headroom target: <= 70% peak utilization
  Status: ACCEPTABLE but near threshold

Memory:
  Current peak: 72% (8GB per server, using ~5.8GB)
  Headroom target: <= 80%
  Status: ACCEPTABLE

Disk (database):
  Current: 120GB used of 500GB (24%)
  Growth: ~8GB/month
  Projected exhaustion: (500 - 120) / 8 = 47.5 months (OK)
  Alert at 80% = 400GB: (400 - 120) / 8 = 35 months (monitor quarterly)

Network:
  Current peak: 2.2 Gbps of 10 Gbps link (22%)
  Status: HEALTHY

=== GROWTH PROJECTION ===

Traffic growth at 15%/month:
  Month 1:  1,000 req/s → 1,150 req/s
  Month 3:  1,000 × 1.15^3  = 1,521 req/s
  Month 6:  1,000 × 1.15^6  = 2,313 req/s
  Month 12: 1,000 × 1.15^12 = 5,350 req/s

Current capacity per server: 500 req/s at 80% CPU
Usable capacity (at 70% CPU): 350 req/s per server
Total usable (4 servers): 1,400 req/s

Projected capacity exhaustion: ~2 months (traffic will hit 1,400 req/s in ~2.6 months)

=== BACK-OF-ENVELOPE: RESOURCES PER REQUEST ===

CPU time per request: ~2ms (measured via profiling)
  At 1,000 req/s: 2 CPU-seconds/second = 2 CPU cores fully busy
  At 2,313 req/s: 4.6 CPU cores — need more than current 4-core servers

Memory per concurrent request: ~2MB (in-flight request state)
  Max concurrent requests: 1,000 req/s × 0.2s avg latency = 200 concurrent
  Memory for requests: 200 × 2MB = 400MB
  Add baseline (JVM/runtime): 2GB
  Total: ~2.4GB per server (out of 8GB) → comfortable

Database connections per server: 25 per app server
  Current: 4 servers × 25 = 100 connections (at pool limit)
  At 6 months: need 8+ servers → 200+ connections
  Action: increase DB pool or add read replicas

=== PROVISIONING PLAN ===

Immediate (this month):
  - Add 2 app servers (increase from 4 to 6)
  - Gives: 6 × 350 = 2,100 req/s usable capacity (comfortable for 3-4 months)

Q3 (3 months):
  - Add 2 more app servers (8 total)
  - Add 1 DB read replica (distribute read load)
  - Evaluate autoscaling setup (HPA in Kubernetes)

Q4 (6 months):
  - Evaluate database sharding or connection pooler (PgBouncer)
  - Review caching strategy (Redis) to reduce DB load
  - Implement horizontal pod autoscaling to handle traffic spikes dynamically

=== ALERTING THRESHOLDS ===

Alert when:
  CPU: sustained > 70% for 5 min → scale up
  Memory: > 80% for 10 min → investigate/scale
  Disk: > 80% full → provision more storage
  DB connections: > 80% of pool → add read replica
  p99 latency: > 300ms → investigate performance
EOF
```

## Task 2 — Record Current System Resources

```bash
echo "" >> ~/practice/capacity_plan.txt
echo "=== ACTUAL SYSTEM SNAPSHOT ($(date -u +%Y-%m-%dT%H:%M:%SZ)) ===" >> ~/practice/capacity_plan.txt
echo "" >> ~/practice/capacity_plan.txt
echo "CPU info:" >> ~/practice/capacity_plan.txt
nproc >> ~/practice/capacity_plan.txt
echo "" >> ~/practice/capacity_plan.txt
echo "Memory:" >> ~/practice/capacity_plan.txt
free -h >> ~/practice/capacity_plan.txt
echo "" >> ~/practice/capacity_plan.txt
echo "Disk:" >> ~/practice/capacity_plan.txt
df -h / >> ~/practice/capacity_plan.txt
```
