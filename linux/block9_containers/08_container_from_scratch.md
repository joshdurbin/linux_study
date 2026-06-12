# Container From Scratch

## The Core Idea

Liz Rice's "containers from scratch" talk (and accompanying Go code) demonstrates that a container is not a special kernel object — it is just a process with the right combination of Linux primitives applied at creation time:

1. New namespaces (PID, UTS, mount, network)
2. A new root filesystem (chroot or pivot_root)
3. /proc mounted inside that root
4. Resource limits applied via cgroups

No container runtime binary is required. A 100-line Go program can replicate the fundamentals.

## Why clone() Instead of fork()+exec()

When you fork, the child inherits the parent's namespaces. To create a process in *new* namespaces from the start, you must pass the `CLONE_NEW*` flags to the `clone()` syscall at process creation time. There is no safe way to "move" a running process into a new PID namespace after creation.

In Go this is done via `cmd.SysProcAttr`:

```go
cmd := exec.Command("/proc/self/exe", append([]string{"child"}, os.Args[2:]...)...)
cmd.SysProcAttr = &syscall.SysProcAttr{
    Cloneflags: syscall.CLONE_NEWUTS |
                syscall.CLONE_NEWPID |
                syscall.CLONE_NEWNS  |
                syscall.CLONE_NEWNET,
}
```

The `/proc/self/exe` trick re-executes the same binary with a "child" argument so the child runs a different code path inside the new namespaces.

## Minimum Steps for a Working Container

### Step 1: New Namespaces
```go
syscall.CLONE_NEWPID | syscall.CLONE_NEWUTS | syscall.CLONE_NEWNS
```

### Step 2: Set Hostname
```go
// Inside child (already in UTS namespace)
syscall.Sethostname([]byte("container"))
```

### Step 3: Change Root Filesystem
```go
// chroot into a minimal rootfs (e.g., an extracted Alpine Linux image)
syscall.Chroot("/home/liz/ubuntufs")
os.Chdir("/")
// Or, properly: pivot_root
```

### Step 4: Mount /proc
```go
syscall.Mount("proc", "/proc", "proc", 0, "")
```

### Step 5: Execute the Requested Command
```go
syscall.Exec(cmd, args, os.Environ())
```

## The Complete Shell Equivalent

```bash
# These five commands replicate what the Go binary does:
sudo unshare --pid --uts --mount --fork \
  sh -c '
    hostname container
    chroot /path/to/rootfs /bin/sh -c "
      mount -t proc proc /proc
      exec /bin/sh
    "
  '
```

## What Real Runtimes Add

| Feature | Shell equivalent / kernel API |
|---------|-------------------------------|
| cgroups | Write PID to `/sys/fs/cgroup/…/cgroup.procs` |
| Network | Create veth pair, put one end in container net ns |
| seccomp | `prctl(PR_SET_SECCOMP, …)` — filter syscalls |
| Capabilities | `capset()` — drop dangerous capabilities |
| AppArmor/SELinux | Set security label via `setxattr` or prctl |
| User namespace | `CLONE_NEWUSER` + write uid_map/gid_map |

The 100-line container only handles the first three steps. A production runtime (runc) implements all of the above, driven by the OCI `config.json`.

## Anatomy of the Go Program

```
func main():
    if args[1] == "child": child()
    else:                   parent()

func parent():
    re-exec self with CLONE_NEW* flags
    wait for child

func child():
    sethostname
    chroot + chdir
    mount /proc
    exec requested command
```

## Key Takeaways

- A container is a process with namespaces + chroot + cgroups applied at creation time.
- `CLONE_NEW*` flags must be passed at process creation via `clone()` — you cannot retroactively move a process into a new PID namespace.
- Go's `cmd.SysProcAttr{Cloneflags: …}` is the `clone()` wrapper.
- The `/proc/self/exe` re-exec pattern lets a single binary run different code paths in the parent and child namespaces.
- Minimal container: new namespaces + chroot + mount /proc + exec = ~50 lines of Go.
- Real runtimes add cgroups, network, seccomp, capabilities, and AppArmor on top.

## Further Reading

- [Liz Rice: Containers from scratch (talk)](https://www.youtube.com/watch?v=8fi7uSYlOdc) — The KubeCon talk this lesson is based on; Liz Rice live-codes a container in Go, demonstrating every step (namespace creation, chroot, /proc mount, cgroups) in 40 minutes.
- [clone(2) man page](https://man7.org/linux/man-pages/man2/clone.2.html) — Documents the `CLONE_NEWPID`, `CLONE_NEWUTS`, `CLONE_NEWNS`, and `CLONE_NEWNET` flags passed in `SysProcAttr.Cloneflags` — the kernel interface underlying Go's `exec.Command` namespace setup.
- [Julia Evans: What even is a container?](https://jvns.ca/blog/2016/10/10/what-even-is-a-container/) — A digestible explanation of how namespaces, chroot, and cgroups combine to create container isolation, with the same "it's just a process" insight as this lesson's core idea.
- [OCI runtime spec](https://github.com/opencontainers/runtime-spec/blob/main/spec.md) — The specification that formalizes the "container from scratch" approach into a standard interface, showing what runc adds (seccomp, capabilities, AppArmor) on top of the minimal 100-line version.
