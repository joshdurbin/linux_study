# Exercise: Kubernetes Architecture

Complete the following tasks. Save your notes to `~/practice/k8s_arch.txt`.

## Task 1 — List All Kubernetes Components

Write out every component with a one-line description:

```bash
mkdir -p ~/practice
cat > ~/practice/k8s_arch.txt << 'EOF'
Kubernetes Architecture
========================

CONTROL PLANE COMPONENTS
--------------------------
kube-apiserver:
  REST API frontend for all K8s operations.
  Validates requests, persists state to etcd.
  All other components communicate ONLY through the API server.

etcd:
  Distributed key-value store (Raft consensus).
  Stores ALL cluster state (pods, services, configs, secrets).
  Only kube-apiserver reads/writes etcd directly.

kube-scheduler:
  Watches for unbound pods (no node assigned).
  Selects best node via filter + score algorithms.
  Writes node assignment back to API server.

kube-controller-manager:
  Runs all built-in controllers (deployment, replicaset, node, service).
  Each controller: watch API server → compare desired vs actual → reconcile.

WORKER NODE COMPONENTS
-----------------------
kubelet:
  Node agent running on every worker node.
  Watches API server for pods assigned to this node.
  Talks to container runtime via CRI (Container Runtime Interface).
  Reports pod/container status back to API server.

kube-proxy:
  Programs iptables/IPVS rules for Service routing.
  Ensures ClusterIP traffic reaches the correct pod endpoints.

container runtime:
  Actually runs containers (containerd, CRI-O).
  kubelet calls it via CRI. Containerd calls runc for OCI containers.

COMMUNICATION RULE
-------------------
Everything talks to kube-apiserver only.
No component has a direct channel to another component.
etcd is ONLY accessed by kube-apiserver.
EOF
```

## Task 2 — Draw the Request Flow

Append a text diagram of how `kubectl apply` flows through the system:

```bash
cat >> ~/practice/k8s_arch.txt << 'EOF'

kubectl apply Flow
-------------------
kubectl (user)
    ↓ HTTPS REST to kube-apiserver
kube-apiserver (authenticates, authorizes, validates)
    ↓ write to etcd
etcd (persists desired state)
    ↑ watch notification
kube-controller-manager (creates ReplicaSet → creates Pod objects)
    ↑ watch notification (pod has no node)
kube-scheduler (selects node, writes nodeName to pod spec)
    ↑ watch notification (pod assigned to this node)
kubelet on selected node
    ↓ CRI call
containerd → runc → container process running
    ↑ status updates back to kube-apiserver
EOF
```

## Task 3 — Note Key Port Numbers

```bash
cat >> ~/practice/k8s_arch.txt << 'EOF'

Key Port Numbers
-----------------
kube-apiserver:    6443 (HTTPS)
etcd:              2379 (client), 2380 (peer)
kubelet:           10250 (API), 10255 (read-only, deprecated)
kube-scheduler:    10259
controller-manager: 10257
NodePort range:    30000-32767
EOF
```

## Task 4 — Check kubectl Connectivity (if available)

```bash
echo "" >> ~/practice/k8s_arch.txt
echo "kubectl cluster-info output:" >> ~/practice/k8s_arch.txt
kubectl cluster-info 2>/dev/null >> ~/practice/k8s_arch.txt || echo "(kubectl not configured or cluster not available)" >> ~/practice/k8s_arch.txt
```
