# Containers and Kubernetes References

Three resources that complement this course's block9 (container internals) and block10 (Kubernetes architecture). Where block9 builds containers from scratch conceptually, these repos make you do it with real code.

---

## containers-from-scratch
**Repo:** https://github.com/lizrice/containers-from-scratch

Liz Rice's famous talk/demo — a minimal container runtime in ~100 lines of Go. Block9/08 covers the theory; this repo is the working code.

### What to Run

```bash
git clone https://github.com/lizrice/containers-from-scratch
cd containers-from-scratch

# Read the source first — it's tiny
cat main.go    # ~100 lines. Every line maps to a concept from block9.
```

### How It Maps to block9

| Go Code | block9 Lesson |
|---------|--------------|
| `syscall.CLONE_NEWUTS` | block9/01 (PID), block5/06 (namespaces) |
| `syscall.CLONE_NEWPID` | block9/01 |
| `syscall.CLONE_NEWNS` | block9/02 (mount namespaces) |
| `syscall.Chroot(fs)` | block9/02 (chroot) |
| `syscall.Exec(cmd, args, os.Environ())` | block5/03 (execve syscall) |
| `cgroups.writeFile(...)` | block9/05, block5/07 (cgroups) |

### Extend It: Add a Network Namespace

After reading the source, add network isolation:

```go
// In the run() function, add to CloneFlags:
syscall.CLONE_NEWNET,

// Then in child():
// Create a veth pair, move one end in, set up IP — same as block6/03
```

### Build and Run (requires root and Linux)

```bash
# Build the container binary
go build -o container .

# Run a shell inside the container (needs a root filesystem)
# Download a minimal rootfs:
mkdir /tmp/alpine-root
curl -sL https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.0-x86_64.tar.gz \
    | tar -xz -C /tmp/alpine-root

# Run it
sudo ./container run /tmp/alpine-root /bin/sh
```

---

## docker-internals-labs
**Repo:** https://github.com/Criseien/docker-internals-labs

Practical labs that reverse-engineer Docker's behavior using only Linux primitives. Exactly the kind of exercise block9 was designed to prepare you for.

### Labs That Extend This Course

**Lab 1: Manual namespace isolation**
Reproduces what `docker run` does with raw `unshare` and `nsenter`:
```bash
# Isolate PID and mount namespaces
sudo unshare --pid --mount --fork bash

# Verify isolation
ps aux    # should show only bash and ps

# Mount /proc for the new namespace
mount -t proc proc /proc
ps aux    # now shows correct PIDs
```

**Lab 2: Overlay filesystem layers**
Extends block9/06 (overlayfs):
```bash
# Create three layers (like three Docker layers)
mkdir -p /tmp/layer1 /tmp/layer2 /tmp/layer3 /tmp/work /tmp/merged

echo "from layer1" > /tmp/layer1/file1.txt
echo "from layer2" > /tmp/layer2/file2.txt
echo "from layer3" > /tmp/layer3/file3.txt

# Stack them: layer3 on top, layer1 at bottom
sudo mount -t overlay overlay \
    -o lowerdir=/tmp/layer3:/tmp/layer2:/tmp/layer1,upperdir=/tmp/work,workdir=/tmp/work \
    /tmp/merged

ls /tmp/merged     # file1.txt, file2.txt, file3.txt all visible
echo "modified" > /tmp/merged/file1.txt    # goes to upperdir, not layer1
```

**Lab 3: cgroup resource limits**
Extends block9/05:
```bash
# Create a cgroup and limit memory to 50MB
mkdir /sys/fs/cgroup/mycontainer
echo $((50 * 1024 * 1024)) > /sys/fs/cgroup/mycontainer/memory.max

# Run a process inside the cgroup
echo $$ > /sys/fs/cgroup/mycontainer/cgroup.procs

# Attempt to allocate more than 50MB
python3 -c "x = bytearray(100 * 1024 * 1024)"  # should get killed by OOM
```

**Lab 4: seccomp syscall filtering**
Not covered in the main course — essential for container security:
```bash
# Create a seccomp profile that denies mkdir
cat > /tmp/deny_mkdir.json << 'EOF'
{
    "defaultAction": "SCMP_ACT_ALLOW",
    "syscalls": [
        {
            "names": ["mkdir"],
            "action": "SCMP_ACT_ERRNO"
        }
    ]
}
EOF

# Apply the profile to a Docker container
docker run --security-opt seccomp=/tmp/deny_mkdir.json ubuntu bash -c "mkdir /tmp/test"
# Should fail: Operation not permitted
```

---

## kubernetes-the-hard-way
**Repo:** https://github.com/kelseyhightower/kubernetes-the-hard-way

The definitive Kubernetes learning resource. Install every component manually, generate every certificate by hand, write every configuration from scratch. Block10 gives you the architecture; this gives you the operational knowledge.

### How It Extends block10

| block10 Lesson | k8s-the-hard-way Equivalent |
|---------------|---------------------------|
| block10/02 (etcd) | Lab: bootstrapping etcd cluster |
| block10/03 (API server) | Lab: bootstrapping control plane, generating certs |
| block10/04 (scheduler) | Lab: starting kube-scheduler with config |
| block10/05 (kubelet) | Lab: configuring and starting kubelet |
| block10/06 (CNI) | Lab: provisioning pod network routes |
| block10/07 (services) | Lab: deploying DNS add-on |

### What You'll Learn Doing This

1. **TLS everywhere** — generate a CA, issue client certs for each component, configure mutual TLS between them. Directly teaches the TLS/PKI gap from the gap analysis.

2. **What kubeadm automates** — doing it by hand shows you exactly what `kubeadm init` does in 30 seconds.

3. **etcd quorum** — seeing why 3 etcd nodes, why odd numbers, what happens when one fails.

4. **CNI plumbing** — adding routes manually, understanding why pod IPs are routable across nodes.

### Key Commands You'll Run (not in block10)

```bash
# Generate CA and certificates (openssl — not covered in this course)
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -out ca.csr -subj "/CN=KUBERNETES-CA"
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt -days 3650

# Inspect a Kubernetes certificate
openssl x509 -in admin.crt -text -noout | grep -A5 "Subject\|Validity\|Issuer"

# Check what kubectl is actually sending
kubectl get pods -v=9 2>&1 | head -30    # shows the raw HTTP request to the API server

# Query etcd directly (bypassing the API server)
ETCDCTL_API=3 etcdctl get / --prefix --keys-only | head -20

# List all resources for a namespace directly from etcd
ETCDCTL_API=3 etcdctl get /registry/pods/default --prefix --keys-only
```

### Kubernetes Operational Skills Not in block10

Block10 is architecture-focused. These kubectl patterns are operational:

```bash
# Debug a failing pod
kubectl describe pod <name>              # events, resource limits, image
kubectl logs <name> --previous           # logs from the previous (crashed) container
kubectl exec -it <name> -- bash          # exec into running container

# Resource limits and QoS class
kubectl get pod <name> -o jsonpath='{.status.qosClass}'
# Guaranteed: requests == limits for all containers
# Burstable: at least one container has requests < limits
# BestEffort: no requests or limits set (evicted first)

# Node resource pressure
kubectl describe node <node>
kubectl top nodes                        # requires metrics-server
kubectl top pods --all-namespaces

# Force reschedule (evict from node)
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Find pods using the most CPU/memory
kubectl top pods --all-namespaces --sort-by=cpu | head -10
kubectl top pods --all-namespaces --sort-by=memory | head -10
```
