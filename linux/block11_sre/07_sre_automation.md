# SRE Automation

## The Automation Imperative

If a human is doing it, it will eventually be done wrong — at 3am, under stress, with incomplete information. Automation is not about job elimination; it is about reliability and scale. A manual process cannot grow as fast as your users.

**Toil target**: SRE teams aim to spend less than 50% of their time on toil (manual, repetitive operational work). The rest should be engineering work that reduces future toil.

## Identifying Toil

A task is toil if it is:
- Manual: requires a human to execute (not just review)
- Repetitive: done more than once or periodically
- Automatable: a machine could do it with the same result
- Grows with scale: more traffic = more manual work

```bash
# Collect toil data: track time per operational task over 2 weeks
# Categories:
#   Deployments    - how many manual deploy steps?
#   Alert response - same runbook action run repeatedly?
#   Provisioning   - manually creating servers, accounts, configs?
#   Reporting      - manually compiling metrics into reports?
```

## Runbook Automation

The first step in eliminating toil: convert runbooks to scripts.

```bash
# Before: runbook says "SSH to host, restart service if heap > 80%"
# After: automated check + action

#!/bin/bash
# check_heap.sh — run via cron every 5 minutes
heap_pct=$(java_heap_used_bytes / java_heap_max_bytes * 100)
if [[ $heap_pct -gt 80 ]]; then
    logger "Heap at ${heap_pct}%, restarting app"
    systemctl restart myapp
    # Alert that auto-restart happened (don't silently paper over problems)
    curl -s -X POST https://alerts.example.com/restart-event \
        -d "{\"service\":\"myapp\",\"heap\":$heap_pct}"
fi
```

The critical rule: automation that takes an action must also alert so engineers know it happened. Silent automation hides problems.

## Configuration Management

Idempotent configuration management means running a tool multiple times produces the same result. This is fundamental to reliable automation.

```bash
# Ansible example: ensure nginx is installed and running
---
- name: Configure web server
  hosts: webservers
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present       # idempotent: only installs if missing
    - name: Deploy config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: reload nginx
    - name: Ensure nginx is running
      service:
        name: nginx
        state: started
        enabled: yes

# Run: ansible-playbook -i inventory.ini site.yml
# Running it 10 times = same result as running it once
```

Tools comparison:
- **Ansible**: agentless, YAML playbooks, SSH-based; good for server config and deployment
- **Terraform**: infrastructure provisioning (VMs, networks, DNS); immutable infrastructure
- **Puppet/Chef**: agent-based; better for large fleets with drift detection

## Continuous Deployment

Deployment pipelines remove humans from the change path:

```
Code merge → CI (tests) → Build image → Push to registry
  → Deploy to staging → Automated integration tests
  → Canary deploy (5% traffic) → Monitor SLOs
  → Promote to 100% OR rollback automatically
```

```bash
# Kubernetes rolling update (built-in CD primitive):
kubectl set image deployment/myapp myapp=myapp:v1.2.3
kubectl rollout status deployment/myapp  # wait for completion
kubectl rollout undo deployment/myapp    # rollback if needed

# Canary with Argo Rollouts:
kubectl argo rollouts set image myapp myapp=myapp:v1.2.3
# Argo Rollouts manages traffic split and automatic analysis
```

## Canary and Blue/Green Deployments

**Canary**: gradually shift traffic to new version; monitor SLOs; auto-rollback if metrics worsen.

**Blue/Green**: maintain two identical environments; switch all traffic at once; rollback = switch back.

```bash
# Blue/Green via Kubernetes Services:
# "blue" deployment running current version
# "green" deployment running new version
# Switch: change Service selector from blue to green
kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'
```

## Chaos Engineering

Chaos engineering proactively injects failures to find weaknesses before real incidents do.

```bash
# Simple chaos: randomly kill a pod in production (Chaos Monkey style)
kubectl delete pod $(kubectl get pods -l app=myapp -o jsonpath='{.items[0].metadata.name}')

# Formal chaos experiments (using Chaos Mesh or LitmusChaos):
#   Network latency injection: add 100ms to all calls to payments service
#   CPU stress: spike CPU on a node to 90%
#   Pod failure: kill 50% of pods in a deployment
#   Node drain: remove a node from the cluster

# GameDay: scheduled team exercise where you inject failures and practice response
```

## Change Management

Most outages are caused by changes. Risk reduction:
- **Pre-deploy checklist**: tests pass, rollback plan ready, monitoring in place
- **Deployment windows**: avoid deploys during peak hours or before weekends
- **Change freeze**: no changes during critical business periods
- **Gradual rollout**: canary → 10% → 50% → 100% with SLO gates between stages

## Key Takeaways

- Automate toil first; build engineering work that pays down future toil.
- Runbook automation: convert manual fixes to scripts, but always alert when they fire.
- Configuration management must be idempotent — same input, same output, every run.
- CD pipelines remove humans from the change path and enforce quality gates.
- Canary deploys allow SLO-gated rollout; blue/green allows instant rollback.
- Chaos engineering finds weaknesses before real incidents do.
- Most outages are caused by changes — deploy gradually with gates.
