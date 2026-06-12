# Kernel and Syscall References

Four resources that go from high-level kernel concepts to reading the actual kernel source. Work through them in order — each one requires the previous.

---

## linux-insides
**Repo:** https://github.com/0xAX/linux-insides

Narrative walkthrough of the Linux kernel's internals — boot process, memory management, syscall implementation, interrupts, timers, scheduling. Written in plain English with inline kernel source references.

### How It Maps to This Course

| linux-insides Chapter | This Course |
|----------------------|-------------|
| Booting | block5/13 |
| Initialization | block5/13 |
| Interrupts | block7/13 (softirq, IRQ affinity) |
| System calls | block5/03 |
| Memory management | block5/08 |
| Timers and time management | block2/17 |
| Synchronization primitives | Not covered |
| Data structures | Not covered |

### Priority Chapters

1. **[System calls](https://0xax.gitbooks.io/linux-insides/content/SysCall/linux-syscall-1.html)** — how `syscall` instruction works at the CPU level, the syscall table, entry points. Essential background for block5/03.
2. **[Interrupts and Interrupt Handling](https://0xax.gitbooks.io/linux-insides/content/Interrupts/linux-interrupts-1.html)** — how IRQs, softirqs, and tasklets work. Directly explains what you see in `/proc/interrupts` and `/proc/softirqs`.
3. **[Memory Management](https://0xax.gitbooks.io/linux-insides/content/MM/linux-mm-1.html)** — buddy allocator, slab allocator, page frames. The mechanism behind `/proc/meminfo`.
4. **[Scheduling](https://0xax.gitbooks.io/linux-insides/content/Initialization/linux-initialization-8.html)** — how CFS is initialized; background for block5/15.

### Things to Try While Reading

```bash
# While reading the syscall chapter:
cat /proc/kallsyms | grep sys_call_table   # the actual syscall table in memory
strace -c ls /tmp                           # counts by syscall

# While reading the interrupts chapter:
watch -n1 cat /proc/interrupts             # watch IRQ counts change in real time
cat /proc/softirqs                         # software interrupt counts per CPU

# While reading memory management:
cat /proc/slabinfo | sort -k3 -rn | head -20   # top slab caches by object count
```

---

## Linux Kernel Labs
**Repo:** https://github.com/linux-kernel-labs/linux-kernel-labs.github.io

University-level kernel development course. Includes lecture slides, labs with skeleton code, and virtual machine setup. This is where you write actual kernel modules and device drivers.

### What This Gives You Beyond This Course

- Writing kernel modules (builds on block5/14 kernel_modules)
- Character device drivers
- Block device drivers
- Memory management from the kernel side
- Synchronization (spinlocks, mutexes, RCU)
- Interrupts and deferred work (workqueues, tasklets)
- Network device drivers

### Priority Labs

1. **[Kernel API](https://linux-kernel-labs.github.io/refs/heads/master/labs/kernel_api.html)** — allocating memory, printing, lists. Foundational for all other labs.
2. **[Kernel Modules](https://linux-kernel-labs.github.io/refs/heads/master/labs/kernel_modules.html)** — hands-on extension of block5/14. Actually compile and load a module.
3. **[Character Device Drivers](https://linux-kernel-labs.github.io/refs/heads/master/labs/device_drivers.html)** — understand how `/dev` entries work from the inside.
4. **[I/O Access](https://linux-kernel-labs.github.io/refs/heads/master/labs/interrupts.html)** — how kernel handles hardware interrupts; connects to block7/13.

### Setup

The labs require a kernel build environment. The repo provides a Docker-based setup:
```bash
git clone https://github.com/linux-kernel-labs/linux-kernel-labs.github.io
# Follow setup instructions in docs/info/vm.rst
```

---

## man-pages
**Repo:** https://github.com/mkerrisk/man-pages

The canonical source for Linux man pages. More useful as a reference than sequential reading — but knowing what's in sections 2, 3, 4, 5, and 7 shapes how you think about the system.

### Man Page Sections Worth Knowing

| Section | Contents | Priority Subsections |
|---------|----------|---------------------|
| 2 | System calls | `read(2)`, `write(2)`, `mmap(2)`, `epoll(2)`, `io_uring(2)`, `clone(2)`, `execve(2)` |
| 3 | Library functions | `malloc(3)`, `pthread_create(3)`, `dlopen(3)` |
| 4 | Device files | `null(4)`, `zero(4)`, `random(4)`, `mem(4)` |
| 5 | File formats | `proc(5)`, `fstab(5)`, `resolv.conf(5)`, `crontab(5)`, `passwd(5)` |
| 7 | Overviews | `signal(7)`, `socket(7)`, `tcp(7)`, `unix(7)`, `namespaces(7)`, `cgroups(7)`, `capabilities(7)`, `epoll(7)` |

### Must-Read Pages (that directly extend this course)

```bash
man 7 signal        # complete signal reference — extends block5/04
man 7 tcp           # TCP socket options — extends block6 and block7/13
man 7 unix          # Unix domain socket details — extends block5/12
man 7 namespaces    # namespace overview — extends block5/06 and block9
man 7 cgroups       # cgroup interface — extends block5/07
man 7 capabilities  # Linux capabilities — extends block3/04
man 2 io_uring_setup  # io_uring API — not covered in course
man 2 epoll_create  # epoll interface — extends block5/11
man 2 clone         # how namespaces are created — extends block9/08
man 5 proc          # /proc filesystem overview — extends block5/01
```

### Reading man Pages with Context

When you encounter an unfamiliar kernel behavior, check section 7 (overview pages) before searching online. The overview pages (`signal(7)`, `tcp(7)`, `capabilities(7)`) often answer "why does this work this way?" in one page.

---

## Torvalds/linux (the kernel source)
**Repo:** https://github.com/torvalds/linux

The actual kernel. Useful for confirming behavior, reading comments that explain non-obvious design decisions, and understanding exactly what a syscall does.

### Navigating the Source

```bash
# Use https://elixir.bootlin.com/linux/latest/source — cross-referenced, searchable

# Key directories for SRE-relevant code:
# kernel/        — core: scheduler (sched/), signals, syscalls
# mm/            — memory management
# net/           — networking stack (ipv4/, ipv6/, core/)
# fs/            — filesystems (proc/, sysfs/, ext4/)
# arch/x86/      — x86 syscall entry (entry/common.c)
# include/uapi/  — userspace API headers (what man pages describe)
```

### Practical Code Reads

| What to read | Path | Why |
|-------------|------|-----|
| CFS scheduler | `kernel/sched/fair.c` | See `vruntime` calculations from block5/15 |
| Syscall table | `arch/x86/entry/syscalls/syscall_64.tbl` | The actual table strace uses |
| TCP state machine | `net/ipv4/tcp_input.c` | How TCP handles retransmits, TIME_WAIT |
| `/proc/loadavg` | `fs/proc/loadavg.c` | The EMA formula from block7/11, in code |
| PSI | `kernel/sched/psi.c` | How `/proc/pressure/*` is computed |
| io_uring | `io_uring/` | The full async I/O implementation |

Use `git log --oneline fs/proc/loadavg.c` to see when and why a specific file changed.
