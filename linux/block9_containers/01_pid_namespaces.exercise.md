# Exercise: PID Namespaces

Complete the following tasks in your terminal. All output should be saved to `~/practice/pid_ns_notes.txt`.

## Task 1 — Document PID Namespace Concepts

Create the practice directory and write a notes file covering:
- What a PID namespace isolates
- Why PID 1 is special inside a namespace
- What happens when PID 1 exits in a namespace

```bash
mkdir -p ~/practice
cat > ~/practice/pid_ns_notes.txt << 'EOF'
PID Namespace Notes
===================
A PID namespace isolates the process ID number space.
Processes inside cannot see processes outside their namespace.
PID 1 is the init process for the namespace.
If PID 1 exits, all other processes in the namespace receive SIGKILL.

unshare command: sudo unshare --fork --pid --mount-proc /bin/bash
  --fork: required with --pid to avoid race conditions
  --pid: create new PID namespace
  --mount-proc: remount /proc so ps shows only namespace-local processes
EOF
```

## Task 2 — Inspect Namespace Inodes

Record the namespace inode for your current shell and PID 1:

```bash
echo "My PID namespace inode:" >> ~/practice/pid_ns_notes.txt
readlink /proc/self/ns/pid >> ~/practice/pid_ns_notes.txt
echo "Host init PID namespace inode:" >> ~/practice/pid_ns_notes.txt
readlink /proc/1/ns/pid >> ~/practice/pid_ns_notes.txt
```

## Task 3 — Document lsns Output

List all PID namespaces visible to your user:

```bash
echo "" >> ~/practice/pid_ns_notes.txt
echo "PID namespaces (lsns):" >> ~/practice/pid_ns_notes.txt
lsns -t pid 2>/dev/null >> ~/practice/pid_ns_notes.txt || echo "(lsns not available)" >> ~/practice/pid_ns_notes.txt
```

## Task 4 — Record NSpid for Your Shell

Check the NSpid entry for your shell process:

```bash
echo "" >> ~/practice/pid_ns_notes.txt
echo "NSpid for current shell:" >> ~/practice/pid_ns_notes.txt
grep NSpid /proc/self/status >> ~/practice/pid_ns_notes.txt
```

## Task 5 — Summarize Docker's Use of PID Namespaces

Append a short explanation of how Docker uses PID namespaces:

```bash
cat >> ~/practice/pid_ns_notes.txt << 'EOF'

Docker and PID Namespaces
--------------------------
Docker creates a new PID namespace per container via clone() with CLONE_NEWPID.
The container entrypoint becomes PID 1 inside the namespace.
The host can still see container processes via /proc, but with host-assigned PIDs.
Namespace identity is tracked via inode in /proc/<PID>/ns/pid.
EOF
```
