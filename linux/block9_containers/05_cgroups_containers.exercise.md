# Exercise: cgroups and Container Resource Limits

Complete the following tasks. Save your notes to `~/practice/cgroups_containers.txt`.

## Task 1 — Document cgroup v2 Key Concepts

```bash
mkdir -p ~/practice
cat > ~/practice/cgroups_containers.txt << 'EOF'
cgroups and Container Resource Limits
=======================================
cgroups (control groups) organize processes into groups with resource limits.
cgroup v2 = unified hierarchy, single tree at /sys/fs/cgroup

Key resource files (cgroup v2):
  memory.max      - hard memory limit (OOM kill if exceeded)
  memory.high     - soft memory limit (throttle before OOM)
  memory.current  - current memory usage
  cpu.weight      - relative CPU share (default 100, range 1-10000)
  cpu.max         - hard CPU bandwidth: "quota period" in microseconds
  cgroup.procs    - PIDs in this cgroup (write PID to assign)

Creating and using a cgroup:
  sudo mkdir /sys/fs/cgroup/myapp
  echo "100M" | sudo tee /sys/fs/cgroup/myapp/memory.max
  echo "50000 100000" | sudo tee /sys/fs/cgroup/myapp/cpu.max
  echo $$ | sudo tee /sys/fs/cgroup/myapp/cgroup.procs

Inspection tools:
  systemd-cgls     - show cgroup tree
  systemd-cgtop    - live resource usage per cgroup
  cat /proc/self/cgroup - show own cgroup path
EOF
```

## Task 2 — Explore the /sys/fs/cgroup Hierarchy

```bash
echo "" >> ~/practice/cgroups_containers.txt
echo "Top-level cgroup entries:" >> ~/practice/cgroups_containers.txt
ls /sys/fs/cgroup/ >> ~/practice/cgroups_containers.txt 2>&1
```

## Task 3 — Read Your Own cgroup Path

```bash
echo "" >> ~/practice/cgroups_containers.txt
echo "Current process cgroup path:" >> ~/practice/cgroups_containers.txt
cat /proc/self/cgroup >> ~/practice/cgroups_containers.txt
```

## Task 4 — Find Available Controllers

```bash
echo "" >> ~/practice/cgroups_containers.txt
echo "Available cgroup controllers:" >> ~/practice/cgroups_containers.txt
cat /sys/fs/cgroup/cgroup.controllers >> ~/practice/cgroups_containers.txt 2>/dev/null || echo "(not available)" >> ~/practice/cgroups_containers.txt
```

## Task 5 — Document Docker/Kubernetes cgroup Mapping

```bash
cat >> ~/practice/cgroups_containers.txt << 'EOF'

Docker to cgroup v2 mapping:
  --memory="100m"   ->  memory.max = 104857600
  --cpus="0.5"      ->  cpu.max = "50000 100000" (50ms per 100ms)
  
Kubernetes to cgroup v2 mapping:
  limits.memory     ->  memory.max
  limits.cpu        ->  cpu.max
  requests.cpu      ->  cpu.weight

Container cgroup location:
  Docker:     /sys/fs/cgroup/system.slice/docker-<id>.scope/
  Kubernetes: /sys/fs/cgroup/kubepods.slice/.../<pod-uid>/
EOF
```
