# Troubleshooting and SRE Practice References

Four resources for building the judgment that turns knowledge into competence: real broken systems, curated exercises, peer case studies, and production-readiness checklists.

---

## SadServers
**Repo / Site:** https://github.com/SadServers/sadservers  
**Interactive:** https://sadservers.com

Real Linux server scenarios where something is broken — your job is to fix it. Think LeetCode but for SREs. Each scenario gives you SSH access to a broken machine.

### Why This Is Different

This course teaches you concepts and exercises in a clean environment. SadServers gives you:
- Broken systems with no hints about what's wrong
- A time limit that simulates incident pressure
- Scenarios with red herrings (just like real incidents)
- A pass/fail validator that checks your fix actually worked

### Recommended Starting Scenarios (Ordered by Difficulty)

| Scenario | What It Tests | Course Connections |
|----------|--------------|-------------------|
| "Santiago" | Find and fix a broken nginx | block2/06, block6 |
| "Bucharest" | Debug a process writing to disk | block7/10 (lsof), block7/03 |
| "Tokyo" | Fix a broken systemd service | block2/06, block2/10 |
| "Taipei" | Disk full — find and free space | block1/01, block7/10 |
| "Lisbon" | Fix a permissions issue | block1/05 |
| "Bern" | Debug a slow application | block7/04 (strace), block7 |
| "Saint John" | Fix broken DNS resolution | block6/06, block6/14 |
| "Salta" | Investigate high load average | block7/11 |
| "Melbourne" | Track down a memory leak | block7/02, block7/09 |
| "Jakarta" | Fix a network namespace issue | block6/03, block9/03 |

### Approach for Each Scenario

Use the USE method (block7/08) as your framework:

```
1. Start with the "First 60 Seconds" checklist (block7/08):
   uptime → vmstat 1 → mpstat -P ALL 1 → pidstat 1 → iostat -xz 1 → free

2. Identify which resource is the bottleneck (CPU, memory, I/O, network).

3. Narrow to the process: ps aux --sort=-%cpu, lsof, ss.

4. Trace the system calls: strace -p <pid>.

5. Check logs: journalctl -xe, dmesg, /var/log/syslog.

6. Fix and verify.
```

### Running Locally

The repo includes a Vagrantfile for running sadserver-style scenarios locally:
```bash
git clone https://github.com/SadServers/sadservers
cd sadservers
# Follow setup in README to run scenarios locally with Vagrant
```

---

## devops-exercises
**Repo:** https://github.com/bregman-arie/devops-exercises

3000+ interview-style questions and exercises covering Linux, networking, containers, Kubernetes, cloud, CI/CD, and more. Use it to audit your knowledge and find specific gaps.

### Sections That Map to This Course

| Section | Maps To | Questions to Focus On |
|---------|---------|----------------------|
| Linux | block1–block5 | Process management, filesystem, networking commands |
| Networking | block6 | TCP/IP, DNS, firewalls, routing |
| Docker | block9 | Container internals, networking, volumes |
| Kubernetes | block10 | Architecture, debugging, RBAC |
| Monitoring | block11 | Prometheus, alerting, SLOs |
| Shell scripting | block1–block2 | Scripting, awk/sed, pipes |

### High-Value Question Categories

**Linux process questions** (test block5 depth):
- What happens when you `fork()` then `exec()`?
- What is a zombie process? How does it occur? How do you clean it up?
- How does `kill -9` differ from `kill -15` at the kernel level?
- What is the difference between `hard` and `soft` limits (`ulimit`)?

**Networking questions** (test block6 depth):
- What is the difference between a bridge and a router?
- Explain the TCP three-way handshake and what happens if a SYN packet is lost.
- What is conntrack and why does it matter for Docker networking?
- What does `net.ipv4.ip_forward` control and when must it be set?

**Kubernetes questions** (test block10 depth):
- What happens when you `kubectl apply -f pod.yaml`? Trace through every component.
- What is a pod's QoS class and how does the scheduler use it?
- Why can't you add resources to a running pod?
- What is the role of kube-proxy and how does it implement ClusterIP services?

---

## how-they-sre
**Repo:** https://github.com/enomorr/how-they-sre

A curated collection of postmortems, blog posts, conference talks, and articles from SRE teams at Google, Netflix, Cloudflare, AWS, Stripe, Uber, and others. The real-world counterpart to block11's conceptual coverage.

### Must-Read Categories

**Postmortems with technical depth:**
- Google's postmortem on the 2019 cloud networking outage — covers BGP, traffic engineering, blast radius
- Cloudflare's BGP leak incident — covers routing table bloat, DDoS-at-scale
- GitHub's database outage — covers replica lag, failover, read/write splitting
- AWS us-east-1 outage 2020 — covers cascading failures, dependency graphs

**SLO implementation in practice:**
- Netflix's approach to error budgets — how they use burn rate alerts
- Stripe's take on reliability — balancing velocity and availability
- Airbnb's alerting philosophy — moving from threshold to symptom-based alerting

**On-call culture:**
- Google's SRE book excerpts on on-call practices
- PagerDuty's incident management guide

### Key Questions to Answer After Reading

1. In the postmortems you read, was the root cause at a layer you understand technically? If not, what do you need to learn?
2. How did the teams detect the incident? What signals fired? Were they the right signals?
3. What would the USE method or Golden Signals have shown during the incident?
4. What change would have prevented or bounded the impact?

---

## sre-checklist
**Repo:** https://github.com/bregman-arie/sre-checklist

A comprehensive production-readiness checklist. Use it to evaluate whether a service is actually ready to run reliably in production. Directly extends block11/08's Production Readiness Review.

### Checklist Sections and Course Connections

**Monitoring and Alerting** (block11/02):
- [ ] Service exposes Prometheus metrics at `/metrics`
- [ ] All four golden signals have dashboards: latency, traffic, errors, saturation
- [ ] Alerts fire on symptoms, not causes (high error rate, not high CPU)
- [ ] Alerts have a runbook linked in the annotation
- [ ] There are no alerts that fire more than once per week without action taken

**On-Call and Incident Response** (block11/03):
- [ ] On-call rotation exists with defined escalation path
- [ ] Runbooks exist for all alerts
- [ ] Postmortem process is defined and blameless
- [ ] Incident severity levels are documented

**Deployments and Change Management** (block11/07):
- [ ] Deployments are automated (no manual steps)
- [ ] Rollback procedure is documented and tested
- [ ] Canary or blue/green deployment is possible
- [ ] Configuration changes are tracked in version control

**Capacity** (block11/05):
- [ ] Resource limits and requests are set (Kubernetes QoS)
- [ ] Load testing results exist for expected peak traffic
- [ ] Auto-scaling policy exists or headroom is explicitly provisioned

**Networking and Security** (block6, block3):
- [ ] TLS is terminated correctly and certificates auto-renew
- [ ] Sensitive secrets are not in environment variables or config maps in plaintext
- [ ] Ingress is rate-limited
- [ ] Egress is restricted to known destinations

### Using the Checklist for a Real Service

Pick any running service (your own, or a public open-source project) and walk through the checklist. For each unchecked item:
1. Does the team know it's missing?
2. Is there a plan to add it?
3. What would happen in an incident without it?

This exercise reveals which parts of block11 are easiest to skip in practice and which ones bite you hardest when you skip them.
