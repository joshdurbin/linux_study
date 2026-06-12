# Kubernetes Architecture

## Overview

Kubernetes is a container orchestration platform built on a **declarative model**: you describe the desired state, and Kubernetes continuously works to reconcile the actual state to match it. This is fundamentally different from imperative scripts that issue step-by-step commands.

## Control Plane Components

The control plane manages the cluster. In a production cluster it runs on dedicated nodes (often 3 for high availability).

### kube-apiserver
- The **single entry point** for all cluster operations
- Validates and processes REST requests
- Reads/writes cluster state to etcd
- All other components communicate through the API server — they do not talk directly to each other

```bash
kubectl get pods -n kube-system | grep apiserver
# Control plane pods are visible from any configured kubectl
```

### etcd
- Distributed key-value store; the single source of truth for all cluster state
- Only the API server reads/writes etcd directly
- Run as a 3 or 5 node cluster for production HA

### kube-scheduler
- Watches for new pods with no assigned node
- Selects the best node using filter + score phases
- Writes the node assignment back to the API server

### kube-controller-manager
- Runs all built-in controllers as goroutines in one binary
- Each controller watches the API server for its resource type and reconciles:
  - Deployment controller: ensures N replicas exist
  - Node controller: handles node failures
  - Service controller: manages cloud load balancers
  - ReplicaSet controller: maintains pod counts

## Worker Node Components

Every node that runs application pods requires:

### kubelet
- The node agent — runs on every node
- Watches the API server for pods assigned to its node
- Calls the container runtime (via CRI) to start/stop containers
- Reports pod status back to the API server
- Manages pod lifecycle probes (liveness, readiness, startup)

### kube-proxy
- Maintains network rules (iptables or IPVS) for Services
- When a Service is created, kube-proxy programs rules so that ClusterIP traffic reaches a pod

### Container Runtime
- Actually runs containers: containerd (default), CRI-O, or Docker (via dockershim, deprecated)
- kubelet communicates via the **Container Runtime Interface (CRI)**

## Communication Pattern

```
kubectl
   ↓ HTTPS/REST
kube-apiserver ←→ etcd
   ↑
scheduler (watches for unbound pods, writes node assignment)
controller-manager (watches resources, reconciles)
   ↓ (API server notifies)
kubelet (on each node, watches for pods assigned to its node)
   ↓ CRI
containerd → runc → container process
```

Rule: **everything talks to the API server**. No component has a direct channel to another component (except etcd, which only the API server talks to).

## The Declarative Model

```bash
# Apply desired state — Kubernetes figures out what to create/update/delete
kubectl apply -f deployment.yaml

# Kubernetes stores this in etcd
# Controllers detect the gap between desired and actual state
# Scheduler assigns pods to nodes
# kubelet creates containers
```

## Exploring the Architecture

```bash
# See all control plane pods
kubectl get pods -n kube-system

# See node components and their status
kubectl get nodes -o wide

# Check API server address
kubectl cluster-info

# Explore the API surface
kubectl api-resources
kubectl api-versions
```

## Key Takeaways

- Control plane: API server, etcd, scheduler, controller-manager
- Worker nodes: kubelet, kube-proxy, container runtime
- All communication goes through kube-apiserver — it is the hub
- etcd is the only persistent store; only the API server accesses it
- Controllers run a reconcile loop: watch → compare desired vs actual → act
- The declarative model means Kubernetes is self-healing by design
