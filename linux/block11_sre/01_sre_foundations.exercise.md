# Exercise: SRE Foundations

Complete the following tasks. Save your notes to `~/practice/sre_foundations.txt`.

## Task 1 — Define SLI, SLO, SLA for a Hypothetical Service

Create notes defining the three metrics for a web API service:

```bash
mkdir -p ~/practice
cat > ~/practice/sre_foundations.txt << 'EOF'
SRE Foundations
================

Hypothetical Service: "OrdersAPI" — handles e-commerce order placement.
Traffic: ~500 req/s, business hours.

SLIs (what we measure):
  1. Availability: successful_requests / total_requests
  2. Latency: % of requests completing in < 300ms
  3. Error rate: 5xx responses / total responses

SLOs (internal targets):
  1. Availability >= 99.9% (monthly)
  2. p99 latency < 300ms
  3. Error rate < 0.1%

SLA (contractual commitment to customers):
  Availability >= 99.5% per month
  Breaching SLA triggers 10% service credit.

Error Budget Calculations (99.9% SLO):
  Monthly budget    = (1 - 0.999) × 30d × 24h × 60min = 43.2 minutes/month
  Weekly budget     = (1 - 0.999) × 7d × 24h × 60min  = 10.1 minutes/week
  Quarterly budget  = (1 - 0.999) × 90d × 24h × 60min = 129.6 minutes/quarter

SLO vs SLA safety margin:
  SLO = 99.9%, SLA = 99.5%
  Internal budget 4x stricter than contractual obligation.
  Even if we burn our full SLO budget, we still meet the SLA.
EOF
```

## Task 2 — Calculate Error Budgets for Different SLOs

```bash
cat >> ~/practice/sre_foundations.txt << 'EOF'

Error Budget Table (monthly, 30 days = 43,200 minutes):
  SLO 99.0%:  budget = 432.0  minutes (7.2 hours)
  SLO 99.5%:  budget = 216.0  minutes (3.6 hours)
  SLO 99.9%:  budget =  43.2  minutes
  SLO 99.95%: budget =  21.6  minutes
  SLO 99.99%: budget =   4.3  minutes

Error budget burn rate:
  If budget is 43.2 min/month and an outage lasts 10 min:
  Burn rate = 10/43.2 = 23% of monthly budget consumed.
  Remaining budget: 33.2 minutes.
EOF
```

## Task 3 — Identify Toil in a Scenario

```bash
cat >> ~/practice/sre_foundations.txt << 'EOF'

Toil Identification for OrdersAPI:
  TOIL examples:
    - Restarting the order service when it hangs (weekly occurrence)
    - Manually rotating API keys for downstream services every 30 days
    - Pulling and emailing a weekly error count report from logs
    - Manually scaling up servers before each peak sales event
    - Responding to the same disk-full alert every 2 weeks

  NOT toil:
    - Designing the autoscaling policy (one-time engineering work)
    - Writing the runbook for disk cleanup (permanent value)
    - Building a dashboard (reduces future investigation time)

  Toil reduction plan:
    - Restart → health check + auto-restart via systemd/Kubernetes liveness probe
    - Key rotation → automated via Vault or secret management system
    - Reports → automated alerting on error rate SLO
    - Scaling → autoscaler (HPA, cluster autoscaler)
    - Disk-full → automated log rotation + alert tuning
EOF
```

## Task 4 — Write the Error Budget Policy

```bash
cat >> ~/practice/sre_foundations.txt << 'EOF'

Error Budget Policy:
  >= 50% budget remaining: teams may deploy freely
  < 50% budget remaining:  require additional testing/review for changes
  < 10% budget remaining:  freeze non-critical deployments, focus on reliability
  0% budget (exhausted):   only critical bug fixes and reliability work until next period

Review cadence:
  Weekly: review current burn rate
  Monthly: SLO review with stakeholders
  Quarterly: SLO target review (raise if consistently met)
EOF
```
