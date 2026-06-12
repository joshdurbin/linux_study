# Exercise: SRE Automation

Complete the following tasks. Save your notes to `~/practice/automation_plan.txt`.

## Task 1 — Write a Toil Reduction Plan

Create a toil reduction plan for a realistic set of operational tasks:

```bash
mkdir -p ~/practice
cat > ~/practice/automation_plan.txt << 'EOF'
Toil Reduction Plan
====================
Team: Platform SRE
Service: OrdersAPI + infrastructure
Assessment period: June 2026

=== TOIL INVENTORY ===

Task: Manual deployment (estimated: 3h/week)
  Current process: engineer SSHs to build server, pulls repo, runs deploy.sh,
                   monitors logs for 20 min, marks ticket done
  Toil score: HIGH (repetitive, manual, every deploy = human required)
  Automation plan: GitHub Actions CI/CD pipeline
    - On merge to main: build + test + push Docker image
    - Argo CD deploys to staging automatically
    - Canary deploy to prod with 5% traffic + SLO check
    - Auto-promote to 100% if SLOs met for 10 min
  Estimated savings: 3h/week → 0.5h/week (review/approve gates)

Task: Restarting crashed app servers (estimated: 2h/week)
  Current process: alert fires, engineer SSHs, runs systemctl restart, confirms
  Toil score: HIGH (same action every time, could be automated)
  Automation plan: systemd auto-restart + liveness probe
    - systemd: Restart=on-failure, RestartSec=5s
    - Kubernetes: liveness probe → automatic container restart
    - Alert on "pod restarted more than 3 times" (not on individual restart)
  Estimated savings: 2h/week → 0.1h/week (investigate recurring crashes)

Task: Weekly log archival (estimated: 1h/week)
  Current process: engineer runs find + gzip + aws s3 cp command
  Toil score: MEDIUM (scripted but not automated)
  Automation plan: cron job
    - /etc/cron.weekly/archive-logs.sh
    - Compress logs older than 7 days, upload to S3 Glacier
    - Alert on failure, send weekly report
  Estimated savings: 1h/week → 0h/week (fully automated)

Task: Provisioning new dev environments (estimated: 4h/request)
  Current process: engineer manually creates VM, installs packages, configures
  Toil score: HIGH (manual, complex, error-prone)
  Automation plan: Terraform + Ansible
    - terraform apply creates VM, DNS, security groups
    - ansible-playbook configures OS, installs dependencies
    - Script: provision-env.sh <name> <size> = fully automated
  Estimated savings: 4h/request → 0.25h/request (review + trigger)

=== PRIORITIZED ROADMAP ===

Month 1 (highest toil):
  - Implement CI/CD pipeline for deployments (saves 3h/week)
  - Enable systemd/Kubernetes auto-restart (saves 2h/week)
  
Month 2:
  - Automate log archival cron job (saves 1h/week)
  - Automate certificate renewal (Let's Encrypt + certbot cron)

Month 3:
  - Terraform + Ansible for environment provisioning
  - Automated capacity alerts with runbook links

=== EXPECTED OUTCOME ===

Current estimated toil: ~15h/week per engineer (50% of 30h work week)
After roadmap: ~5h/week per engineer (17% of work week)
Freed time: 10h/week for reliability engineering work
EOF
```

## Task 2 — Document Configuration Management Idempotency

```bash
cat >> ~/practice/automation_plan.txt << 'EOF'

Idempotency in Configuration Management
-----------------------------------------
Idempotent: running the same operation N times produces the same result as running it once.

Why it matters:
  - Safe to re-run on failure (no partial state corruption)
  - Can run on drift correction without risk
  - Enables scheduled convergence runs (cron Ansible, every 30 min)

Idempotent examples:
  Ansible: "state: present" only installs if missing
  Terraform: "resource" blocks describe desired state; no-op if already correct
  Shell: [[ -f /etc/myapp.conf ]] || cp default.conf /etc/myapp.conf

Non-idempotent anti-patterns:
  echo "config" >> /etc/myapp.conf     # appends every run
  useradd myapp                         # fails if user exists
  Solution: use Ansible's user/lineinfile modules instead
EOF
```
