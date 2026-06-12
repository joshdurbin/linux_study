# Postmortems

## What Is a Postmortem?

A **postmortem** (also called an incident review or after-action review) is a structured written record of an incident: what happened, why it happened, what the impact was, and what will be done to prevent recurrence. Postmortems turn incidents into learning opportunities.

The two most important qualities of a postmortem:

1. **Blameless**: Focus on systems, processes, and tooling — not individual mistakes. People operate within the constraints given to them. If one person could cause an outage, the system design is the problem.

2. **Actionable**: Every postmortem must produce specific, assigned, time-boxed action items. A postmortem without action items is just documentation of a failure.

## Blameless Culture

Blaming individuals:
- Creates fear that prevents honest reporting
- Causes engineers to hide mistakes or work around unsafe systems
- Does not fix the underlying systemic problem (someone else will make the same mistake)

Blameless alternative:
- "Why did the system allow this to happen?"
- "What made this mistake easy to make?"
- "How do we make doing the right thing the easy thing?"

## Postmortem Structure

### 1. Summary
One paragraph: what failed, when, how long, and user impact. Written so an executive can understand it.

### 2. Impact
Quantified user impact:
- Duration: how long was service degraded/down
- Error rate during incident
- Number of users/requests affected
- Error budget burned (% of monthly SLO budget)

### 3. Timeline
Chronological list of events with times (use UTC):

```
14:02 UTC  Alert fires: error_rate > 1% for 2 minutes
14:04 UTC  On-call engineer acknowledges alert
14:08 UTC  Incident declared SEV2; IC assigned
14:11 UTC  Deploy at 13:45 identified as likely cause
14:15 UTC  Rollback initiated: kubectl rollout undo deployment/orders-api
14:19 UTC  Error rate drops to < 0.1%; monitoring continues
14:31 UTC  Error rate stable; incident resolved
```

### 4. Root Cause Analysis

The **root cause** is the deepest systemic cause — the thing that, if fixed, would prevent this class of incident. Contributing factors are conditions that made the impact worse.

#### Five Whys Technique

Start with the symptom and ask "why?" until you reach a systemic root cause:

```
Problem: Orders API returned 500 errors for 29 minutes

Why 1: The database connection pool was exhausted
Why 2: A new endpoint was making N+1 queries (one query per order item)
Why 3: The endpoint was not code-reviewed for query efficiency
Why 4: No query count assertion exists in tests or staging
Why 5: The team has no policy requiring performance testing for DB-touching code

Root cause: No process to catch query efficiency regressions before production
```

### 5. Action Items

Each action item must be:
- **Specific**: "Add slow query log alerting with threshold 100ms"
- **Assigned**: Name of owner (not "the team")
- **Time-boxed**: Due date (not "soon")

| Action | Owner | Priority | Due |
|--------|-------|----------|-----|
| Add query count assertion to CI | Backend lead | P1 | +1 week |
| Enable slow query log + alerting | DBA | P1 | +3 days |
| Add DB connection pool saturation alert | SRE | P2 | +1 week |
| Review all new endpoints for N+1 patterns | Backend lead | P2 | +2 weeks |

## Sharing Postmortems

Good postmortem culture includes:
- Publishing postmortems internally so other teams can learn
- Weekly/monthly SRE meetings to review recent postmortems
- Linking postmortems to monitoring improvements and code changes

## Key Takeaways

- Blameless postmortems focus on systemic causes, not individual mistakes.
- Structure: summary → impact → timeline → root cause → action items.
- Five Whys: iteratively ask "why?" until reaching a systemic root cause.
- Action items must be specific, assigned, and time-boxed — not vague intentions.
- The value of a postmortem is in the action items and sharing of learnings.
- Track action items in your ticketing system; review completion in postmortem reviews.
