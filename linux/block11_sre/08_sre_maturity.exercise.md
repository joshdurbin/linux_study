# Exercise: SRE Maturity and Production Readiness

Complete the following tasks. Save your review to `~/practice/sre_readiness.txt`.

## Task 1 — Complete a Mini Production Readiness Review

Create a PRR for a hypothetical new service:

```bash
mkdir -p ~/practice
cat > ~/practice/sre_readiness.txt << 'EOF'
Production Readiness Review
============================
Service: RecommendationsAPI
Version: 1.0.0
Review Date: 2026-06-11
Reviewer: SRE Team

=== SERVICE DESCRIPTION ===
Provides product recommendations for the e-commerce platform.
Called by OrdersAPI and ProductAPI. Non-critical path (orders succeed without it).
Expected traffic: 200 req/s peak, p99 latency target < 100ms

=== RELIABILITY AND AVAILABILITY ===

[PASS] SLIs defined:
  - Availability: successful_requests / total_requests
  - Latency: p99 request duration

[PASS] SLO defined: 99.5% availability, p99 < 100ms
  (Lower SLO acceptable: non-critical path, graceful degradation in callers)

[PASS] Error budget policy: documented in team wiki

[PASS] Dependencies identified:
  - Redis cache (if down: fall through to DB)
  - PostgreSQL (if down: return empty recommendations with 200 OK)
  - ML model service (if down: return rule-based fallback)

[PASS] Single points of failure addressed: 3 replicas, across 3 availability zones

=== MONITORING AND ALERTING ===

[PASS] Four golden signals measured in Prometheus

[PASS] Alerts defined:
  - Page: error rate > 5% for 2 min
  - Ticket: sustained SLO burn > 0.5%/hour

[PASS] Dashboard created: grafana.internal/d/recommendations

[PASS] Structured logging: JSON to stdout, shipped to Loki

=== INCIDENT RESPONSE ===

[PASS] Runbook written: wiki.internal/runbooks/recommendations-api
  Covers: high error rate, latency spike, cache miss storm, ML fallback

[PASS] On-call: added to platform rotation

[PASS] Escalation: Platform SRE → ML Platform team

[PASS] Postmortem process: same as platform standard

=== CAPACITY AND SCALING ===

[PASS] Load test completed:
  Tested at 500 req/s (2.5× expected peak)
  p99 = 85ms (under 100ms target) at 500 req/s
  Resource usage: CPU 62%, memory 58% at 500 req/s

[PASS] HPA configured: min 3, max 12 replicas on CPU > 70%

[PASS] Resource limits set:
  requests: cpu=100m, memory=256Mi
  limits:   cpu=500m, memory=512Mi

[PASS] DB connection pool: 10 per pod, 30 total at min replicas (< 200 max)

=== DEPLOYMENT SAFETY ===

[PASS] CI/CD: GitHub Actions → build → test → staging deploy → canary
[PASS] Rollback: kubectl rollout undo tested in staging
[PASS] Feature flag: ML vs rule-based fallback controlled via LaunchDarkly
[PASS] Deployment runbook: 15-minute deploy with 5-min canary + SLO gate

=== SECURITY ===

[PASS] No secrets in code; uses Vault sidecar injector
[PASS] Runs as non-root (UID 1000); read-only root filesystem
[PASS] NetworkPolicy: only allows traffic from OrdersAPI and ProductAPI
[PASS] Image scanned: no critical CVEs (trivy)

=== DOCUMENTATION ===

[PASS] Architecture diagram: in repo /docs/architecture.png
[PASS] Dependency map: wiki.internal/services/recommendations
[PASS] Runbook: covers 5 most common alert scenarios
[PASS] Service catalog: updated

=== RESULT ===

APPROVED for production launch.
All PRR items passed.

Outstanding action items (non-blocking):
  - Add /metrics/slow endpoint tracking (P3, sprint 2)
  - Explore eBPF-based latency tracing (P3, Q3 planning)

=== SRE MATURITY ASSESSMENT ===

Current stage for this service: PROACTIVE
  - SLOs defined, monitoring in place, runbooks written
  - Error budget policy documented
  - Not yet: chaos testing, game days, SLO optimization (target for Q4)
EOF
```

## Task 2 — Document the Four Maturity Stages

```bash
cat >> ~/practice/sre_readiness.txt << 'EOF'

SRE Maturity Stages
--------------------
REACTIVE:
  - No SLOs; respond to alerts reactively
  - Heroics required to keep services running
  - High toil; no runbooks
  - Target: establish SLOs and basic monitoring

PROACTIVE:
  - SLOs defined and monitored
  - Runbooks written for common alerts
  - On-call rotation established
  - Error budget tracked
  - Target: enforce error budgets; build automation

PREVENTION:
  - Error budgets enforced (slow down deploys when exhausted)
  - Chaos engineering + game days practiced
  - Toil below 40% of SRE time
  - Pre-deployment reviews (PRR) gate launches
  - Target: reduce toil to < 30%; improve SLO targets

OPTIMIZATION:
  - Toil below 30%; mostly engineering work
  - SLO targets regularly reviewed and raised
  - Reliability built into development process (not bolted on)
  - Game days routine; chaos experiments automated
  - Team can absorb 2× growth without proportional headcount increase
EOF
```
