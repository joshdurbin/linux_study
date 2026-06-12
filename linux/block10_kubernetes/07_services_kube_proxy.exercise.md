# Exercise: Services and kube-proxy

Complete the following tasks. Save your notes to `~/practice/services_notes.txt`.

## Task 1 — Document Service Types

```bash
mkdir -p ~/practice
cat > ~/practice/services_notes.txt << 'EOF'
Kubernetes Services and kube-proxy Notes
==========================================

Service Types
--------------
ClusterIP (default):
  Virtual IP accessible only inside the cluster.
  Stable IP + DNS name fronting a set of pods.
  kube-proxy programs iptables DNAT rules for routing.

NodePort:
  Opens a port (30000-32767) on EVERY node.
  External traffic: <nodeIP>:<nodePort> → ClusterIP → pod.
  Useful for dev/testing; not recommended for production.

LoadBalancer:
  Cloud provider provisions an external load balancer.
  LB forwards to NodePort on nodes → ClusterIP → pod.
  Used in GKE, EKS, AKS for production external access.

ExternalName:
  Returns a CNAME DNS record to an external hostname.
  No proxying; just DNS aliasing.
  Use case: make external services addressable by K8s DNS name.

Headless (clusterIP: None):
  No ClusterIP assigned.
  DNS returns actual pod IPs directly.
  Required by StatefulSets for stable per-pod DNS.
EOF
```

## Task 2 — Document iptables Routing for ClusterIP

```bash
cat >> ~/practice/services_notes.txt << 'EOF'

ClusterIP Routing via iptables
---------------------------------
kube-proxy programs these iptables chains:

Packet flow:
  1. Client sends to ClusterIP:port
  2. iptables KUBE-SERVICES chain matches destination IP
  3. Jumps to KUBE-SVC-<hash> chain (one per service)
  4. KUBE-SVC randomly selects one of N endpoints (via statistic module)
  5. Jumps to KUBE-SEP-<hash> chain (one per endpoint/pod)
  6. DNAT: rewrites destination to podIP:containerPort
  7. Packet routed to pod via CNI

View rules:
  sudo iptables -t nat -L KUBE-SERVICES -n -v
  sudo iptables -t nat -L KUBE-SVC-XXXX -n -v
  sudo iptables -t nat -L KUBE-SEP-XXXX -n -v

IPVS mode (alternative):
  kube-proxy can use IPVS (IP Virtual Server) kernel module.
  Better performance at scale (1000s of services).
  More load balancing algorithms: rr, lc, sh, dh.
  View: ipvsadm -ln
EOF
```

## Task 3 — Document EndpointSlices

```bash
cat >> ~/practice/services_notes.txt << 'EOF'

EndpointSlices vs Endpoints
-----------------------------
Old Endpoints object: single object listing ALL pod IPs for a service.
Problem at scale: updating 1 pod in a 1000-pod service rewrites the whole object.
Result: thundering herd of etcd writes + kube-proxy updates across all nodes.

EndpointSlice: chunks of ≤100 endpoints per slice.
Only the affected slice needs updating.
Result: O(changed pods) updates instead of O(total pods).

kubectl get endpointslices -n default
kubectl describe endpointslice <name>

kube-proxy watches EndpointSlices (not Endpoints) in Kubernetes 1.21+.
EOF
```

## Task 4 — Note DNS for Services

```bash
cat >> ~/practice/services_notes.txt << 'EOF'

Service DNS Names
------------------
Full form: <service>.<namespace>.svc.cluster.local
Short form within same namespace: <service>
Short form from different namespace: <service>.<namespace>

Examples:
  kubernetes.default.svc.cluster.local    (API server service)
  myapp.production.svc.cluster.local      (myapp in production ns)
  
  Within same namespace: just "myapp"
  From another namespace: "myapp.production"

Headless service DNS:
  Returns individual pod IPs (A records), not a ClusterIP.
  StatefulSet pods also get stable DNS:
    <pod-name>.<service>.<namespace>.svc.cluster.local
    e.g., postgres-0.postgres.default.svc.cluster.local
EOF
```
