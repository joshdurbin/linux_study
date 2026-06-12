# PID Namespaces

## What Is a PID Namespace?

A PID namespace isolates the process ID number space. Processes inside a new PID namespace only see processes that belong to the same namespace — they cannot see processes on the host or in other namespaces. The first process created in a new PID namespace gets PID 1, regardless of what PID it holds on the host.

PID 1 is special: it is the init process for that namespace. If PID 1 exits, the kernel sends SIGKILL to all other processes in the namespace, cleaning up automatically.

## Creating a PID Namespace

The `unshare` command launches a process with one or more namespaces detached from the parent:

```bash
# Create a new PID namespace (--fork required with --pid)
# --mount-proc re-mounts /proc so ps and top see only namespace-local processes
sudo unshare --fork --pid --mount-proc /bin/bash
```

Inside the new shell:

```bash
echo $$          # prints 1 — this shell is PID 1 in the namespace
ps aux           # shows only processes in this namespace
```

On the host (separate terminal):

```bash
ps aux | grep bash   # the same shell appears with its host PID (e.g., 4821)
```

## Inspecting Namespace Identities

Every process has a symlink for each namespace under `/proc/<PID>/ns/`:

```bash
ls -la /proc/self/ns/pid        # shows inode of current PID namespace
ls -la /proc/1/ns/pid           # PID namespace of the host init process
```

Two processes sharing the same inode number are in the same namespace.

```bash
# Compare namespace inodes
readlink /proc/self/ns/pid
readlink /proc/$$/ns/pid
```

## PID Namespace Nesting

PID namespaces are hierarchical. A parent namespace always sees the host PIDs of child processes — visibility flows upward, never downward. A process in a child namespace cannot see its parent namespace's process tree.

## What Docker Does

Docker creates a new PID namespace for every container:

```bash
docker run --rm alpine ps aux    # shows only container processes

# Inspect namespace from host
docker inspect <container_id> | grep -i pid
ls -la /proc/<container_pid>/ns/pid
```

Each container's init process (PID 1) is typically the entrypoint command.

## Useful Tools

```bash
# Show process tree
pstree -p              # host-wide tree with PIDs

# Inside unshare'd shell
pstree -p              # only this namespace's tree

# List all PID namespaces (requires lsns)
lsns -t pid

# Find what namespace a process is in
cat /proc/<PID>/status | grep NSpid
```

`NSpid` in `/proc/<PID>/status` shows the PID as seen from each ancestor namespace — useful for mapping host PIDs to container PIDs.

## Key Takeaways

- PID namespaces provide process isolation without virtualization.
- `unshare --fork --pid --mount-proc` is the minimal incantation for a working isolated process view.
- PID 1 inside a namespace acts as init; its exit terminates the namespace.
- Docker, Podman, and runc all create a new PID namespace per container.
- Namespaces are identified by inode numbers accessible via `/proc/PID/ns/`.

## Further Reading

- [pid_namespaces(7) man page](https://man7.org/linux/man-pages/man7/pid_namespaces.7.html) — Documents PID namespace nesting rules, the special role of PID 1 as init (SIGKILL all on exit), the `NSpid` field in `/proc/PID/status`, and visibility rules between parent and child namespaces.
- [clone(2) man page](https://man7.org/linux/man-pages/man2/clone.2.html) — Documents the `CLONE_NEWPID` flag and why `--fork` is required with `unshare --pid`, covering the difference between `clone()` (create child in new namespace) and `unshare()` (move caller into new namespace).
- [LWN: PID namespaces](https://lwn.net/Articles/531419/) — The LWN article introducing PID namespaces, explaining the nesting hierarchy and how nested namespaces map PIDs — the background theory for the "NSpid shows PID in each ancestor namespace" feature.
- [Julia Evans: What even is a container?](https://jvns.ca/blog/2016/10/10/what-even-is-a-container/) — Shows how Docker uses PID namespaces so `ps aux` inside a container shows only container processes, connecting the `unshare --pid` demonstration to real Docker behavior.
