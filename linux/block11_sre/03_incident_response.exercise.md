# Exercise: Incident Response

Complete the following tasks. Save your runbook to `~/practice/incident_runbook.md`.

## Task 1 — Write a General Incident Response Runbook Template

```bash
mkdir -p ~/practice
cat > ~/practice/incident_runbook.md << 'EOF'
# Incident Response Runbook

## Purpose
This runbook guides the on-call engineer through the standard incident response
process from detection through postmortem.

## Incident Roles

**Incident Commander (IC):**
- Coordinates all response activities; does NOT personally debug
- Delegates tasks and tracks who is working on what
- Maintains the incident timeline
- Declares severity level and escalations
- Communicates closure and initiates postmortem

**Communications Lead:**
- Updates status page (statuspage.io or similar)
- Sends internal Slack updates every 30 minutes
- Drafts customer-facing email if SLA at risk

**Subject Matter Experts (SMEs):**
- Investigate and fix specific areas as directed by IC
- Report findings to IC before taking major actions

## Severity Classification

| Level | Definition | Response |
|-------|------------|----------|
| SEV1  | Complete outage, all users affected | Immediate page, declare major incident |
| SEV2  | Major degradation, many users affected | Page on-call team + manager |
| SEV3  | Minor degradation, some users affected | Ticket, fix in business hours |
| SEV4  | Cosmetic / no user impact | Normal backlog |

## Response Checklist

### Detection Phase
- [ ] Alert received or issue reported
- [ ] Confirm the issue is real (check dashboards, not just the alert)
- [ ] Declare incident and assign IC
- [ ] Set up incident channel: #incident-YYYY-MM-DD-description
- [ ] Classify severity

### Triage Phase
- [ ] Identify affected services and user populations
- [ ] Check recent changes (deploys, config changes, infrastructure changes)
- [ ] Check external dependencies (third-party APIs, cloud provider status)
- [ ] Assign SMEs to investigate

### Mitigation Phase
- [ ] Apply fastest mitigation first (rollback, feature flag, traffic shift)
- [ ] Verify mitigation is working (metrics improving)
- [ ] Communicate update to stakeholders
- [ ] Continue investigation with service restored

### Resolution Phase
- [ ] Confirm metrics have fully recovered
- [ ] Confirm no lingering user impact
- [ ] Document root cause (preliminary)
- [ ] Schedule postmortem within 48-72 hours
- [ ] Close incident channel and send final update

## Diagnostic Commands

```bash
# Check recent deploys
git log --oneline -20
kubectl rollout history deployment/myapp

# Check error rate in last 30 minutes
# (replace with your monitoring query)
curl -G 'http://prometheus:9090/api/v1/query' \
  --data-urlencode 'query=rate(http_requests_total{status=~"5.."}[5m])'

# Check pod health
kubectl get pods --all-namespaces | grep -v Running
kubectl describe pod <failing-pod>

# Check recent events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Check logs
kubectl logs <pod> --previous --tail=100
journalctl -u myapp --since "30 minutes ago"
```

## Mitigation Decision Tree

```
Error rate elevated?
├── Started after a deploy?
│   └── YES → Rollback: kubectl rollout undo deployment/myapp
├── Started after config change?
│   └── YES → Revert config via git revert + deploy
├── High traffic / overload?
│   └── YES → Rate limit or scale up: kubectl scale deployment/myapp --replicas=10
├── Dependency unhealthy?
│   └── YES → Enable circuit breaker / fallback mode via feature flag
└── Unknown cause?
    └── Gather more data; post update at 30min mark regardless
```

## Communication Templates

**Initial (within 5 min of declaration):**
"Incident declared: elevated error rate on OrdersAPI. IC: [name]. Investigating now."

**Update (every 30 min):**
"Update: [current status]. We have identified [X / are still investigating cause].
Next update in 30 minutes."

**Mitigated:**
"Mitigated at [time]. Error rates restored to normal. Root cause investigation ongoing."

**Resolved:**
"Resolved at [time]. [Brief cause]. Full postmortem to follow within 48 hours."
EOF
```

## Task 2 — Record the Incident Lifecycle Steps

Append a quick reference summary of the lifecycle:

```bash
cat >> ~/practice/incident_runbook.md << 'EOF'

## Quick Reference: Incident Lifecycle
1. Detection  - alert fires or user reports issue
2. Triage     - assess severity, assign IC, identify scope
3. Mitigation - restore service (rollback, scale, feature flag)
4. Resolution - root cause confirmed, permanently fixed
5. Postmortem - blameless review, action items, share learnings
EOF
```
