# Exercise: Container From Scratch

Complete the following tasks. Save your notes to `~/practice/container_scratch.txt`.

## Task 1 — Write the 5-Step Container Recipe

Document the five minimum steps to build a container from scratch:

```bash
mkdir -p ~/practice
cat > ~/practice/container_scratch.txt << 'EOF'
Container From Scratch — 5-Step Recipe
========================================
Based on Liz Rice "containers from scratch" (lizrice/containers-from-scratch)

Step 1: Create new namespaces at process creation time
  Use clone() with CLONE_NEWPID | CLONE_NEWUTS | CLONE_NEWNS | CLONE_NEWNET
  In Go: cmd.SysProcAttr = &syscall.SysProcAttr{Cloneflags: syscall.CLONE_NEWPID | ...}
  Cannot use fork() then move — CLONE_NEWPID must be at creation time

Step 2: Set hostname (UTS namespace)
  syscall.Sethostname([]byte("container"))
  Or: hostname container (shell)

Step 3: Chroot/pivot_root into a rootfs
  syscall.Chroot("/path/to/rootfs") + os.Chdir("/")
  Better: pivot_root (used by runc) — atomically swaps root, old root unmountable
  Rootfs can be an extracted Docker image (docker export | tar -x)

Step 4: Mount /proc inside the new root
  syscall.Mount("proc", "/proc", "proc", 0, "")
  Without this: ps, top show host processes even inside the namespace

Step 5: Exec the requested command
  syscall.Exec(cmd, args, env)  — replaces the child process

Result: isolated process with its own PID 1, hostname, filesystem view
EOF
```

## Task 2 — Document What Real Runtimes Add

```bash
cat >> ~/practice/container_scratch.txt << 'EOF'

What Real Container Runtimes (runc) Add on Top
------------------------------------------------
cgroups:
  Write container PID to /sys/fs/cgroup/<slice>/cgroup.procs
  Set memory.max, cpu.max before exec

Network setup:
  Create veth pair
  Move one end into container net namespace
  Attach other end to host bridge (docker0)
  Configure IP addresses and routes

seccomp:
  prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, ...)
  Block dangerous syscalls (ptrace, mount, etc.)

Capabilities:
  capset() to drop all capabilities except needed ones
  Default Docker: ~14 of 40+ capabilities kept

AppArmor / SELinux:
  Apply MAC policy label to the container process

User namespace (rootless):
  CLONE_NEWUSER + write /proc/self/uid_map and gid_map
EOF
```

## Task 3 — Document the Go Binary Re-exec Pattern

```bash
cat >> ~/practice/container_scratch.txt << 'EOF'

The /proc/self/exe Re-exec Pattern
-------------------------------------
Problem: parent and child need to run different code, but child must start
         in new namespaces before any code runs.

Solution:
  Parent: re-exec the same binary (/proc/self/exe) with "child" as first arg
          and CLONE_NEW* flags so the new process starts in new namespaces
  Child:  detect "child" arg and run container setup code

In Go:
  cmd := exec.Command("/proc/self/exe", append([]string{"child"}, os.Args[2:]...)...)
  cmd.SysProcAttr = &syscall.SysProcAttr{Cloneflags: ...}
  cmd.Run()

This avoids needing a separate binary for the container init process.
EOF
```

## Task 4 — Note the Shell Equivalent

```bash
cat >> ~/practice/container_scratch.txt << 'EOF'

Shell Equivalent (what the Go program does, in shell):
  sudo unshare --pid --uts --mount --fork sh -c '
    hostname container
    chroot /path/to/rootfs sh -c "
      mount -t proc proc /proc
      exec /bin/sh
    "
  '
EOF
```
