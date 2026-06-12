# Exercise: Kubernetes Networking and CNI

Complete the following tasks. Save your notes to `~/practice/cni_notes.txt`.

## Task 1 — Document the Kubernetes Networking Model

```bash
mkdir -p ~/practice
cat > ~/practice/cni_notes.txt << 'EOF'
Kubernetes Networking and CNI Notes
=====================================

The Kubernetes Networking Model (3 Rules)
-------------------------------------------
1. Every pod gets its own unique IP address
2. Pods can communicate with any other pod without NAT
3. Agents on a node can communicate with all pods on that node

Result: pod-to-pod communication is like host-to-host — direct IP routing.

Three distinct IP spaces:
  Pod CIDR:     IP addresses for pods          (e.g., 10.244.0.0/16)
  Service CIDR: Virtual IPs for Services       (e.g., 10.96.0.0/12)
  Node CIDR:    Physical IP addresses of nodes (e.g., 192.168.1.0/24)

Each node gets a slice of the pod CIDR:
  node1: 10.244.0.0/24
  node2: 10.244.1.0/24
  node3: 10.244.2.0/24
EOF
```

## Task 2 — Document CNI Plugin Workflow

```bash
cat >> ~/practice/cni_notes.txt << 'EOF'

CNI Plugin Workflow
--------------------
CNI = Container Network Interface
When a pod starts, kubelet calls the CNI plugin with:
  - Container network namespace path (/proc/<PID>/ns/net)
  - Pod name, namespace, and desired network config

CNI plugin steps:
  1. Create a veth pair (virtual ethernet cable with two endpoints)
  2. Place one end (eth0) inside the pod's network namespace
  3. Place other end (vethXXXXXX) on the host
  4. Assign IP from the node's pod CIDR slice to pod's eth0
  5. Configure routes so traffic to this pod IP routes to this veth
  6. For cross-node traffic: set up overlay (VXLAN) or BGP routes
  7. Return IP address to kubelet/API server

CNI files:
  /opt/cni/bin/          - CNI plugin executables
  /etc/cni/net.d/        - CNI configuration files
EOF
```

## Task 3 — Compare CNI Plugins

```bash
cat >> ~/practice/cni_notes.txt << 'EOF'

CNI Plugin Comparison
----------------------
Flannel:
  Technology: VXLAN overlay
  Pros: simple, widely used
  Cons: no NetworkPolicy support, encapsulation overhead

Calico:
  Technology: BGP (native) or VXLAN
  Pros: NetworkPolicy, high performance with BGP mode
  Cons: BGP mode requires router configuration

Cilium:
  Technology: eBPF (kernel programs, no iptables)
  Pros: highest performance, L7 policy, deep observability, Hubble UI
  Cons: requires newer kernels (5.10+)

Weave:
  Technology: encrypted VXLAN mesh
  Cons: slower than Cilium/Calico
EOF
```

## Task 4 — Document CoreDNS

```bash
cat >> ~/practice/cni_notes.txt << 'EOF'

CoreDNS
--------
CoreDNS runs in kube-system namespace, provides cluster DNS.

DNS format for services:
  <service-name>.<namespace>.svc.cluster.local

DNS format for pods:
  <pod-ip-dashes>.<namespace>.pod.cluster.local
  e.g., 10-244-0-5.default.pod.cluster.local

Pod /etc/resolv.conf (injected by kubelet):
  nameserver 10.96.0.10
  search default.svc.cluster.local svc.cluster.local cluster.local

Short names work due to search domains:
  nslookup myservice            -> myservice.default.svc.cluster.local
  nslookup myservice.other-ns   -> myservice.other-ns.svc.cluster.local
EOF
```
