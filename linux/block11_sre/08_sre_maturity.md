# SRE Maturity and Production Readiness

## The SRE Maturity Model

Organizations move through stages as their SRE practice matures:

| Stage | Behavior | Characteristics |
|-------|---------|----------------|
| **Reactive** | Fight fires | No SLOs, no runbooks, heroics required, high toil |
| **Proactive** | Prevent known failures | SLOs defined, monitoring in place, runbooks written |
| **Prevention** | Eliminate failure classes | Error budgets enforced, chaos testing, pre-mortems |
| **Optimization** | Continuously improve | SLO targets raised, toil below 30%, reliability is engineered |

Most organizations start reactive. The goal is not to jump to optimization immediately, but to move one stage at a time.

## Production Readiness Review (PRR)

A **PRR** is a structured checklist a service must pass before going to production. It prevents launching services that will immediately become operational burdens.

### PRR Checklist

**Reliability and Availability**
- [ ] SLIs and SLOs defined and documented
- [ ] Error budget policy in place
- [ ] Dependencies identified; single points of failure addressed
- [ ] Graceful degradation when dependencies fail

**Monitoring and Alerting**
- [ ] All four golden signals (latency, traffic, errors, saturation) are measured
- [ ] Alerts defined for SLO breaches; no alert fires without action
- [ ] Dashboards created and shared with team
- [ ] Log aggregation configured; structured logging in use

**Incident Response**
- [ ] Runbooks written for all alerts
- [ ] On-call rotation established and tested
- [ ] Escalation path documented
- [ ] Postmortem process in place

**Capacity and Scaling**
- [ ] Load test completed at 2× expected peak traffic
- [ ] Autoscaling configured (horizontal and/or vertical)
- [ ] Resource limits set in production (CPU, memory)
- [ ] Database connection pool sized correctly

**Deployment Safety**
- [ ] CI/CD pipeline with automated tests
- [ ] Rollback procedure tested and documented
- [ ] Feature flags available for risky changes
- [ ] Deployment runbook or playbook written

**Security**
- [ ] No secrets in code or environment variables (use Vault or K8s Secrets)
- [ ] Service runs with minimum necessary privileges
- [ ] Network policies restrict unnecessary traffic
- [ ] Dependency vulnerabilities scanned

**Documentation**
- [ ] Architecture diagram up to date
- [ ] Dependency map documented
- [ ] Operational runbooks cover all common issues
- [ ] Service catalog entry updated

## SRE Organizational Models

### Embedded SRE
SRE engineers sit within product teams. Pros: deep product context; fast feedback loop. Cons: can become pure dev team; hard to maintain SRE standards.

### Centralized SRE
A central SRE team supports all product teams. Pros: consistent standards; strong reliability culture. Cons: bottleneck; may be distant from product context.

### Consulting SRE
SRE team consults on best practices; product teams own their own operations. Pros: scales well. Cons: harder to enforce standards.

## Game Days and Chaos Experiments

A **game day** is a scheduled, controlled exercise where the team intentionally breaks something to practice response and find weaknesses.

```bash
# Game day exercise structure:
# 1. Define hypothesis: "If DB primary fails, checkout degrades gracefully"
# 2. Establish baseline metrics
# 3. Inject failure: kill DB primary
# 4. Observe: does the system degrade as expected?
# 5. Restore: fix the issue
# 6. Debrief: what worked, what didn't, action items

# Tools:
# Chaos Mesh: Kubernetes-native chaos engineering
# LitmusChaos: CNCF chaos engineering platform
# gremlin: commercial chaos platform
# Manual: kubectl delete pod, iptables DROP rules
```

## Toil Budget and Error Budget Meetings

Regular cadence:
- **Weekly**: review current SLO burn rate and on-call toil
- **Monthly**: SLO review with product and engineering leadership
- **Quarterly**: SLO target review; adjust if consistently over- or under-achieving

Error budget meeting agenda:
1. How much budget was consumed this period?
2. What caused the largest burns?
3. Are action items from last period complete?
4. Should we adjust deployment pace or reliability investment?

## Key Takeaways

- Maturity stages: reactive → proactive → prevention → optimization. Progress one stage at a time.
- PRR gates new services at launch to prevent operational debt from day one.
- Game days build muscle memory for incident response and surface hidden weaknesses.
- Embed SRE practices: SLOs, monitoring, runbooks, and PRR checklists scale the culture.
- Regular error budget reviews align engineering priorities with reliability outcomes.
- The goal is reliability through engineering, not reliability through heroics.
