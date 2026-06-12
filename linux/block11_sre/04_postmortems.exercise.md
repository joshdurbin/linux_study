# Exercise: Postmortems

Complete the following tasks. Write a fictional postmortem to `~/practice/postmortem_example.md`.

## Task 1 — Write a Complete Fictional Postmortem

Create a realistic postmortem for a database outage scenario:

```bash
mkdir -p ~/practice
cat > ~/practice/postmortem_example.md << 'EOF'
# Postmortem: Database Connection Exhaustion — 2026-06-04

**Status:** Resolved  
**Severity:** SEV2  
**Date:** 2026-06-04  
**Duration:** 29 minutes (14:02–14:31 UTC)  
**Author:** On-call SRE  

---

## Summary

On 2026-06-04 from 14:02 to 14:31 UTC, the OrdersAPI experienced a 29-minute
period of elevated error rates (peak 34% error rate) caused by database connection
pool exhaustion. A newly deployed endpoint introduced an N+1 query pattern that
multiplied database load by 8x during a moderate traffic spike. Approximately 14,200
checkout requests failed. This consumed 67% of the June error budget.

---

## Impact

- **Duration:** 29 minutes
- **Error rate peak:** 34% (SLO target: < 0.1%)
- **Failed requests:** ~14,200 checkout API calls
- **User impact:** Customers unable to place orders; ~8,400 unique users affected
- **Error budget:** 19.6 minutes of 43.2 minute monthly budget consumed (67%)
- **Revenue estimate:** Approximately $42,000 in lost order value

---

## Timeline

All times UTC.

| Time  | Event |
|-------|-------|
| 13:45 | Deploy v2.14.1 of orders-api completes; includes new /orders/bulk endpoint |
| 14:02 | Alert fires: orders_error_rate > 1% sustained 2 minutes |
| 14:04 | On-call engineer (Jane) acknowledges alert |
| 14:06 | Jane opens dashboard: error rate 12% and rising, all errors are 500 |
| 14:08 | SEV2 incident declared; Jane assumes IC role; posts in #incidents |
| 14:10 | Database team pinged (SME: Carlos) |
| 14:11 | Jane correlates error spike start time with 13:45 deploy |
| 14:13 | Carlos confirms DB connection pool at 100% utilization; pool_wait_time 8s |
| 14:14 | IC decision: rollback deploy immediately, diagnose after |
| 14:15 | Rollback initiated: kubectl rollout undo deployment/orders-api |
| 14:17 | New pods starting; error rate still 34% (peak) |
| 14:19 | Rollback completes; error rate begins falling |
| 14:22 | Error rate < 1%; pool utilization dropping |
| 14:27 | Error rate < 0.1%; pool utilization 40% (normal) |
| 14:31 | Incident resolved; stakeholder communication sent |
| 15:00 | Carlos identifies N+1 query pattern in /orders/bulk endpoint |

---

## Root Cause Analysis

### Contributing Factors
1. New /orders/bulk endpoint made one DB query per order item (N+1 pattern)
2. A traffic spike to this endpoint at 14:01 caused query volume to jump 8x
3. Database connection pool (max 100 connections) was exhausted within 60 seconds
4. No circuit breaker to shed load when pool is saturated

### Five Whys

**Why did OrdersAPI return 500 errors?**
The database connection pool was exhausted; requests could not get a connection.

**Why was the connection pool exhausted?**
Query volume increased 8x due to the new /orders/bulk endpoint's N+1 query pattern.

**Why did an N+1 query pattern reach production?**
The code review for this endpoint did not check for query efficiency.

**Why was query efficiency not checked in code review?**
The team has no checklist item or policy requiring DB query review for new endpoints.

**Why does no such policy exist?**
The team grew quickly and did not establish performance standards as a formal process.

**Root cause:** Absence of a development process requiring query performance review
and staging load testing for database-touching code.

---

## Action Items

| # | Action | Owner | Priority | Due |
|---|--------|-------|----------|-----|
| 1 | Add DB query count assertions to integration tests for all endpoints | Backend Lead | P1 | 2026-06-11 |
| 2 | Enable slow query logging in staging (threshold: 50ms) | DBA | P1 | 2026-06-08 |
| 3 | Add connection pool saturation alert (alert at 80% full) | SRE | P1 | 2026-06-09 |
| 4 | Add N+1 query check to code review checklist | Engineering Manager | P2 | 2026-06-15 |
| 5 | Implement connection pool circuit breaker (shed at 90% full) | Backend Lead | P2 | 2026-06-25 |
| 6 | Run load test for all endpoints touching DB before next major deploy | QA Lead | P2 | 2026-07-01 |

---

## Lessons Learned

- Mitigating via rollback before full diagnosis was the right call; it saved ~15 min.
- The 29-minute detection-to-mitigation time was too long for a SEV2; target is < 15 min.
- A connection pool saturation alert would have caught this before user impact.
- N+1 queries are easy to write but expensive at scale; team training would help.
EOF
```
