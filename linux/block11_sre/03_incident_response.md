# Incident Response

## What Is an Incident?

An **incident** is any unplanned interruption or degradation of a service that affects users or burns error budget significantly. Not every alert is an incident — but anything that requires human intervention beyond a simple runbook check is a candidate.

Incidents have a lifecycle with defined roles and communication patterns. An ad hoc response without structure leads to confusion, slower mitigation, and incomplete postmortems.

## Incident Lifecycle

```
Detection → Triage → Mitigation → Resolution → Postmortem
```

1. **Detection**: Alert fires, user reports issue, or someone notices something wrong.
2. **Triage**: How severe is this? Which users/systems are affected? Declare the incident.
3. **Mitigation**: Stop the bleeding — restore service, even if imperfectly (revert, failover).
4. **Resolution**: Root cause identified and addressed. Service fully restored.
5. **Postmortem**: Document what happened, why, and what prevents recurrence.

**Key principle**: Mitigate first, diagnose second. A 30-minute investigation before reverting a bad deploy is worse than reverting immediately and investigating with the service restored.

## Incident Roles

### Incident Commander (IC)
- Coordinates all response activities
- Delegates tasks; does NOT personally debug
- Keeps the incident timeline
- Declares severity and escalations
- Ends the incident and calls for postmortem

### Communications Lead
- Updates status page and internal stakeholders
- Drafts customer-facing communication
- Manages the timeline of external updates

### Subject Matter Experts (SMEs)
- Brought in to investigate and fix specific areas
- Report findings to IC; do not work in parallel without coordinating

## Severity Levels

| Severity | Impact | Response |
|----------|--------|----------|
| SEV1 | Complete outage; all users affected | Immediate page, all hands |
| SEV2 | Major degradation; many users affected | Page on-call + lead |
| SEV3 | Minor degradation; some users affected | Ticket; fix during business hours |
| SEV4 | Cosmetic issue; no SLO impact | Normal development queue |

## On-Call Practices

```bash
# A good on-call rotation has:
# - Clear escalation paths (who to call if primary doesn't respond in 15 min)
# - Runbooks for every common alert
# - Compensation or time off in lieu for pages outside hours
# - Maximum page rate targets (no more than N pages/shift)
```

Runbooks should include:
- Alert name and meaning
- Diagnostic commands to run
- Decision tree: if X → do Y
- Links to dashboards and logs
- Escalation path

## Mitigation Strategies

| Strategy | When to Use |
|----------|------------|
| **Rollback** | New deploy is the likely cause; revert to previous version |
| **Feature flag** | Disable specific feature without full rollback |
| **Traffic shaping** | Shed load, rate limit, or failover to alternate region |
| **Capacity increase** | Add instances/nodes to absorb demand |
| **Circuit break** | Disable integration with failing dependency |

## Communication During an Incident

```
Every 30 minutes at minimum:
  "Update: still investigating the cause of elevated error rates.
   Service is degraded but not fully down. Next update in 30 min."

When mitigated:
  "The incident has been mitigated. Error rates have returned to normal.
   We are monitoring and will investigate root cause."

When resolved:
  "Fully resolved as of 14:32 UTC. Postmortem will follow within 48 hours."
```

## The STAR Framework

For incident writeups and postmortems:
- **S**ituation: what was happening
- **T**ask: what needed to be done
- **A**ction: what was done and why
- **R**esult: what happened as a result

## Key Takeaways

- Incidents follow a lifecycle: detection → triage → mitigation → resolution → postmortem.
- Mitigate first (restore service), diagnose second (find root cause).
- Define incident roles (IC, comms lead, SMEs) before the incident happens.
- Runbooks make on-call sustainable; update them after every incident.
- Regular updates during an incident reduce customer anxiety even if you have no new information.
- Severity levels align response urgency to business impact.
