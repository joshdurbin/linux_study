# SRE Foundations

## What Is SRE?

**Site Reliability Engineering (SRE)** is the practice of applying software engineering principles to operations work. It originated at Google and has been widely adopted to bridge the gap between development speed and operational stability.

The key insight: reliability is a software problem, not a manual process problem. If a human has to do it, it can fail and it won't scale.

## SRE vs Traditional Ops

| Traditional Ops | SRE |
|-----------------|-----|
| Change is risk; resist it | Measured risk via error budgets |
| Manual runbooks, heroics | Automation first |
| Reactive: fix what breaks | Proactive: prevent failures |
| Separated from dev | Embedded or partnered with dev |
| Success = no outages | Success = reliability at acceptable cost |

## SLI — Service Level Indicator

An SLI is a **quantitative measurement** of service behavior. Good SLIs directly reflect the user experience.

Common SLIs:
- **Availability**: `successful_requests / total_requests`
- **Latency**: fraction of requests served in < 200ms
- **Error rate**: `error_requests / total_requests`
- **Throughput**: requests per second

```bash
# Example: calculate availability from logs
total=$(grep -c "" access.log)
errors=$(grep -c " [45][0-9][0-9] " access.log)
echo "Availability: $(echo "scale=4; ($total - $errors) / $total * 100" | bc)%"
```

## SLO — Service Level Objective

An SLO is a **target value** for an SLI. It defines what "good enough" looks like.

Examples:
- 99.9% of requests succeed (availability SLO)
- 99th percentile latency < 500ms
- Error rate < 0.1%

An SLO of 99.9% availability allows **43.8 minutes of downtime per month**.

```
SLO = 99.9%
Allowed error rate = 1 - 0.999 = 0.001 = 0.1%
Monthly error budget = 0.001 × 30 days × 24 hours × 60 min = 43.2 minutes
```

## SLA — Service Level Agreement

An SLA is a **contractual commitment** to customers, usually with financial penalties for breach. SLAs are typically looser than internal SLOs to leave a safety margin.

```
SLA: 99.5% availability (contractual, with refunds)
SLO: 99.9% availability (internal target, 4x stricter)
```

## Error Budget

The error budget is the **allowed amount of unreliability** within a time period:

```
Error budget = 1 - SLO

For 99.9% availability SLO:
  Monthly budget = 0.1% of 30 days = 43.2 minutes
  Quarterly budget = 0.1% of 90 days = 129.6 minutes

Error budget burned by:
  - Outages
  - Planned maintenance (if ungraceful)
  - Latency violations
```

Error budgets drive decisions: if you've burned your budget, you slow down deployments and focus on reliability. If you have budget remaining, you can take more risk.

## Toil

**Toil** is manual, repetitive, automatable work that scales linearly with service load:
- Running deployment scripts by hand
- Manually restarting crashed services
- Responding to the same alert with the same fix every time

SRE teams target spending < 50% of time on toil. The rest goes to engineering work that reduces future toil.

## Key Takeaways

- SRE treats reliability as a software engineering problem.
- SLI: what you measure; SLO: your target; SLA: your contractual promise.
- Error budget = (1 - SLO) × time period — the allowed "budget" for failure.
- Error budgets balance innovation risk against reliability investment.
- Toil is repetitive operational work; eliminating it is a core SRE goal.
- SLOs should be tighter than SLAs to leave a safety buffer.
