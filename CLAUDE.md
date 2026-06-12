# linux_study — agent guide

An 8-week Linux/SRE training app: live Docker terminal in the browser, lesson notes, interactive exercises, automated check scripts, and progress tracking.

## Layout

```
linux_study/
├── main.go              # cobra CLI: `serve` and `version`
├── serve.go             # HTTP server, WebSocket time tracking, shared helpers
├── linux_serve.go       # Linux study handlers (file, check, terminal, stats, completions)
├── go.mod / go.sum
├── Makefile
├── Dockerfile.linux     # Ubuntu 24.04 study container (make linux-image)
├── CLAUDE.md            # ← this file
├── .claude/skills/      # /add-linux-lesson
├── web/
│   ├── linux.html       # study page: xterm.js terminal + lesson pane + exercise pane
│   └── dashboard.html   # progress dashboard (Chart.js)
├── internal/
│   ├── docker/          # container lifecycle manager + WebSocket PTY relay
│   │   ├── manager.go   # GetOrCreate, BuildStudyImage, ExecCheck, Status
│   │   └── terminal.go  # HandleTerminal: binary=stdin, text JSON=resize
│   ├── db/              # SQLite: goose migrations + sqlc store + CompletionStore
│   │   ├── migrations/  # 00001_init, 00002_editor_state, 00003_linux
│   │   ├── queries/     # sqlc query definitions
│   │   ├── store/       # sqlc-generated code
│   │   ├── db.go        # Open + Migrate
│   │   └── completions.go  # raw-SQL completion tracking (exercise_checks table)
│   └── analytics/       # session middleware, time/open/run tracking
└── linux/               # 8-week curriculum (11 blocks, 106 topics)
    ├── block1_basics/        # Week 1: navigation, files, permissions, processes, I/O, env, packages, users
    ├── block2_intermediate/  # Week 1: scripting, text processing, apt/dpkg, systemd, cron, rsync, time, logrotate
    ├── block3_advanced/      # Week 1: advanced scripting, storage, LVM, perf debugging, security
    ├── block4_tooling/       # Week 1: vim, tmux, git advanced, jq/yq
    ├── block5_internals/     # Week 2: /proc, /sys, syscalls, signals, IPC, namespaces, cgroups, FDs, sockets, boot
    ├── block6_networking/    # Week 3: ip/ss, routing, netns, bridges, tcpdump, DNS, nc, nmap, socat, tshark
    ├── block7_performance/   # Week 4: perf, flame graphs, strace, ftrace, I/O, lsof, pprof, USE method
    ├── block8_ebpf/          # Week 5: eBPF intro, BCC tools, bpftrace one-liners → advanced
    ├── block9_containers/    # Week 6: namespaces, cgroups, overlayfs, OCI/runc, scratch container
    ├── block10_kubernetes/   # Week 7: etcd, API server, scheduler, kubelet, CNI, services, storage
    └── block11_sre/          # Week 8: error budgets, SLOs, incidents, monitoring, capacity, postmortems
```

## Linux lesson file conventions

Each lesson is identified by its `.md` file. Three files per topic:

| Suffix | Purpose |
|--------|---------|
| `<topic>.md` | Lesson notes — rendered as markdown in the left pane |
| `<topic>.exercise.md` | Exercise instructions — shown below notes |
| `<topic>.check.sh` | Bash validation — runs inside Docker container, exits 0=pass |

Check scripts run via `bash -s` with stdin = script content. Print `PASS: desc` / `FAIL: desc` per check. Exit 0 only when all checks pass.

`safePathLinux` (in `linux_serve.go`) validates paths against `linuxSectionDirs` and allows only `.md` and `.check.sh` extensions.

## How the server works

- `cobra` CLI. `serve` command auto-migrates on startup, auto-builds the Docker image if missing.
- Root `/` redirects to `/linux`.
- `/linux` — serves `web/linux.html` with the full lesson tree via Go templates.
- `/api/linux/file` — returns lesson notes + exercise markdown + has_check flag.
- `/api/linux/check` — reads `.check.sh`, pipes it to `bash -s` inside the container, records pass/fail.
- `/api/linux/completions` — returns all lesson paths the current session has passed.
- `/api/linux/stats` — aggregated stats for the dashboard (opens, time, checks, weekly completions).
- `/ws` — WebSocket for time tracking: focus/blur/tick frames. Accepts paths starting with `linux/`.
- `/ws/linux-terminal` — WebSocket PTY relay: binary frames = stdin, text JSON = resize.
- Docker manager: one container per session cookie (30-min idle cleanup). `BuildStudyImage` runs async on startup if `linux-study:latest` is missing; falls back to `ubuntu:24.04`.
- SQLite + goose migrations. `exercise_checks` table tracks pass/fail per lesson per session.

## Build / run

```bash
make build              # go build -o linux_study .
make run                # build + serve on :8080 (auto-migrates, auto-builds image)
make linux-image        # docker build -f Dockerfile.linux -t linux-study:latest .
make linux-shell        # interactive shell in the study container
go build ./...          # whole-module build
```

## Adding content

Use `/add-linux-lesson` — it knows the file format, block placement, check script pattern, and naming conventions.

Manual placement rules:
- File prefix `NN_` controls sort order in the sidebar
- New blocks: add the dir + register it in `linuxSectionDirs` (linux_serve.go) and `loadLinuxSections`
- The web app rescans on every page load — no restart needed
