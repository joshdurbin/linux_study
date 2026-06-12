# SRE Curriculum References

Three open curricula that define what a well-rounded SRE should know. Each takes a different angle — use them to fill gaps and deepen understanding beyond the exercises in this course.

---

## LinkedIn School of SRE
**Repo:** https://github.com/linkedin/school-of-sre

LinkedIn's internal SRE onboarding program, open-sourced. The most comprehensive end-to-end curriculum for SRE fundamentals.

### What It Covers (and How It Maps Here)

| School of SRE Module | This Course |
|---------------------|-------------|
| Linux Basics | block1–block3 |
| Python & Web | Not covered here — see repo |
| Git | block4/03 |
| Networking | block6 |
| Databases (MySQL, NoSQL) | Not covered here — see repo |
| Big Data | Not covered here |
| Systems Design | block11 (partial) |
| Metrics & Monitoring | block11/02, block11/09 |
| Capacity Planning | block11/05 |

### Priority Sections to Read

1. **[Linux Basics](https://linkedin.github.io/school-of-sre/level101/linux_basics/intro/)** — review to check your mental model of file permissions, processes, and memory
2. **[Linux Intermediate](https://linkedin.github.io/school-of-sre/level101/linux_intermediate/package-management/)** — systemd deep, package management, git ops
3. **[Networking](https://linkedin.github.io/school-of-sre/level101/networking/intro/)** — OSI model reinforcement, TCP/IP stack, DNS, load balancers (not covered in this course)
4. **[Databases](https://linkedin.github.io/school-of-sre/level101/databases_sql/intro/)** — replication, backups, connection pooling: critical SRE knowledge not in this course
5. **[Metrics and Monitoring](https://linkedin.github.io/school-of-sre/level102/metrics_and_monitoring/introduction/)** — Prometheus data model, PromQL, alerting philosophy (supplements block11)

### Unique Value
The databases and Python modules are the clearest gaps relative to this course. The monitoring module has practical Prometheus examples that complement block11's conceptual coverage.

---

## OpsSchool Curriculum
**Repo:** https://github.com/opsschool/curriculum

Community-written curriculum covering traditional ops/SRE fundamentals. Older but thorough on topics that haven't changed: DNS, HTTP, storage, security fundamentals.

### Priority Sections to Read

1. **[DNS](http://www.opsschool.org/en/latest/dns_101.html)** — zone files, DNSSEC, split-horizon, delegation: goes deeper than block6/06
2. **[HTTP](http://www.opsschool.org/en/latest/http_101.html)** — request/response lifecycle, caching headers, status codes, keep-alive: not covered in this course
3. **[Load Balancing](http://www.opsschool.org/en/latest/load_balancing_101.html)** — L4 vs L7, HAProxy, health checks, sticky sessions: not covered in this course
4. **[Security](http://www.opsschool.org/en/latest/security_101.html)** — TLS, PKI, firewall design: supplements block3/04
5. **[Storage](http://www.opsschool.org/en/latest/storage_101.html)** — RAID, NFS, iSCSI, object storage: supplements block3/02 and block3/06

### Unique Value
HTTP and load balancing chapters are the biggest gap this course has. OpsSchool has clear, practical coverage of both topics.

---

## Linux Upskill Challenge
**Repo:** https://github.com/livialima/linuxupskillchallenge

A 20-day practical challenge, one task per day, targeting sysadmins new to Linux. The challenge format (real server, real tasks) is excellent for building muscle memory.

### How to Use It

Work through the daily challenges on the Docker container you already have running (`make linux-shell`). Each day takes 30–60 minutes.

| Days | Topics | Supplements |
|------|--------|-------------|
| 1–5 | Navigation, users, permissions | block1 |
| 6–10 | Processes, services, networking | block1–block2 |
  | 11–15 | Package management, scripts, scheduling | block2 |
| 16–20 | Logs, security, firewall | block2–block3 |

### Unique Value
The challenge emphasis on doing things on a real (or realistic) system, under time pressure, is different from structured lessons. Good for building confidence and speed.

### Specific Exercises Worth Doing

- **Day 12** — `grep` and `awk` pipelines on real log files
- **Day 15** — Writing your first real cron job for a maintenance task
- **Day 18** — `ufw` and `fail2ban` setup (fail2ban not covered in this course)
- **Day 20** — Hardening a server: `sshd_config` audit, port scan with `nmap`
