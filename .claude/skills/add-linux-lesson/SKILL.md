---
name: add-linux-lesson
description: Add a new Linux lesson to the study guide — a topic with lesson notes, a terminal exercise, and an automated check script. Use when the user wants to add a new topic under linux/. Creates three files: .md (lesson), .exercise.md (tasks), .check.sh (validation).
---

# Add a Linux Lesson

Creates a new lesson under the appropriate `linux/blockN_*/` directory. Each lesson teaches one coherent concept via readable notes, a concrete terminal exercise, and a bash check script that validates completion.

## Curriculum Blocks

| Block | Week | Focus |
|-------|------|-------|
| `block1_basics` | 1 | navigation, files, permissions, processes, I/O, environment, packages, users |
| `block2_intermediate` | 1 | shell scripting, text processing, networking tools, archives, monitoring, systemd, apt |
| `block3_advanced` | 1 | advanced scripting, storage, performance debugging, security hardening |
| `block4_tooling` | 1 | vim, tmux, git advanced, jq/yq |
| `block5_internals` | 2 | /proc, /sys, syscalls, signals, IPC, namespaces, cgroups v2, kernel memory |
| `block6_networking` | 3 | ip/ss, routing, netns+veth, bridges, tcpdump, DNS, firewalling, HTTP tools |
| `block7_performance` | 4 | perf, flame graphs, strace, ftrace, I/O analysis, USE method |
| `block8_ebpf` | 5 | eBPF intro, BCC tools, bpftrace one-liners through advanced use |
| `block9_containers` | 6 | PID/mnt/net/user namespaces, cgroups, overlayfs, OCI/runc, scratch container |
| `block10_kubernetes` | 7 | etcd, API server, scheduler, kubelet, CNI, services, storage |
| `block11_sre` | 8 | error budgets, SLOs, incidents, monitoring, capacity planning, postmortems |

## Files to Create

For a new topic `<topic>` (snake_case) in `linux/<block>/`:

| File | Purpose |
|------|---------|
| `linux/<block>/NN_<topic>.md` | Lesson notes — rendered as markdown in the left pane |
| `linux/<block>/NN_<topic>.exercise.md` | Exercise instructions — shown below the notes |
| `linux/<block>/NN_<topic>.check.sh` | Validation script — runs inside the Docker container |

`NN` is the next available numeric prefix in the block directory. Read the existing files to pick the correct number.

## Lesson (.md) Template

```markdown
# Topic Title

One sentence: what this teaches and when you'd use it.

## Section Heading

Explanation with accurate technical content. Include command examples in fenced code blocks.

```bash
command --flag arg    # short comment on what this does
command2              # another example
```

## Another Section

More content. Tables work well for reference material.

| Column | Column |
|--------|--------|
| value  | meaning |
```

Style:
- Be technically accurate — verify commands work in Ubuntu 24.04
- Prefer showing real command output in comments
- 300-600 words is the target length
- Reference `/proc`, `/sys`, or `/etc` paths where relevant

## Exercise (.exercise.md) Template

```markdown
# Exercise: Topic Name

## Tasks

1. **Task name**: Do X. Save the result to `~/practice/<topic>_<thing>.txt`.

2. **Task name**: Run `command`. Note Y. Write your findings to `~/practice/<topic>_notes.txt`.

3. **Task name**: Create `~/practice/<topic>_example.conf` with the following structure: ...

## Hints

- Hint about a common mistake or shortcut
- Command that helps if stuck
```

Rules:
- 3-5 tasks
- Each task has a concrete, checkable deliverable (a file that exists, has specific content, has specific permissions, etc.)
- Tasks build progressively — start easy, end with something that requires understanding
- All output files go under `~/practice/`

## Check Script (.check.sh) Template

```bash
#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "output file exists"              "[[ -f ~/practice/<topic>_notes.txt ]]"
check "output file is non-empty"        "[[ -s ~/practice/<topic>_notes.txt ]]"
check "output contains expected string" "grep -qi 'keyword' ~/practice/<topic>_notes.txt"
check "config file has correct syntax"  "grep -qE 'pattern' ~/practice/<topic>_example.conf"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

Rules:
- Exit 0 = all checks passed; non-zero = at least one failed
- Print `PASS: description` or `FAIL: description` for each check so the user sees what failed
- Check file existence, non-empty, and content — not exact content (user may phrase things differently)
- Avoid checking for live system state (running processes, loaded modules) — check files the student wrote
- `sudo` is available inside the container if the check needs elevated reads

## After Creating Files

1. `chmod +x linux/<block>/NN_<topic>.check.sh`
2. Verify the lesson loads: `go run . serve` and open `/linux`, find the new lesson
3. The web app rescans on every page load — no restart needed

## Reference

See `linux/block2_intermediate/08_apt_pinning.*` for a good example of a well-structured lesson, exercise, and check script at intermediate difficulty.
