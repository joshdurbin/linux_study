# Kubernetes Networking and CNI

## The Kubernetes Networking Model

Kubernetes defines a flat, routable networking model with three rules:

1. **Every pod gets its own IP address**
2. **Pods can communicate with any other pod without NAT** (within the cluster)
3. **Agents on a node can communicate with all pods on that node**

This means pod-to-pod communication looks like host-to-host communication — no port mapping, no NAT, just direct IP routing. The complexity of implementing this is delegated to CNI plugins.

## Container Network Interface (CNI)

**CNI** is a specification (and a set of libraries) that defines how container runtimes call network plugins to configure networking for a container's network namespace.

When a pod is created, kubelet calls the CNI plugin with:
- The container's network namespace path (`/proc/<PID>/ns/net`)
- The pod name, namespace, and IP allocation request

The CNI plugin:
1. Creates a veth pair (one end in pod namespace, one on host)
2. Assigns an IP from the node's pod CIDR range
3. Sets up routing rules so the pod IP is reachable from other nodes
4. Returns the IP back to kubelet

```bash
# CNI plugin binaries
ls /opt/cni/bin/

# CNI configuration (tells kubelet which plugin to use)
ls /etc/cni/net.d/
cat /etc/cni/net.d/10-containerd-net.conflist
```

## Common CNI Plugins

| Plugin | Technology | Features |
|--------|-----------|---------|
| Flannel | VXLAN overlay | Simple, widely used, limited policy |
| Calico | BGP or VXLAN | NetworkPolicy, eBPF option |
| Cilium | eBPF | Deep observability, L7 policy, high performance |
| Weave | VXLAN mesh | Simple setup, multicast support |

## IP Address Spaces

```bash
# Three independent CIDR ranges:
# Pod CIDR:     IP addresses for pods (e.g., 10.244.0.0/16)
# Service CIDR: Virtual IPs for Services (e.g., 10.96.0.0/12)
# Node CIDR:    Host IPs for nodes (e.g., 192.168.1.0/24)

# Each node gets a slice of the pod CIDR:
# node1: 10.244.0.0/24  (pods get IPs 10.244.0.x)
# node2: 10.244.1.0/24  (pods get IPs 10.244.1.x)

# View pod CIDR per node
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}  {.spec.podCIDR}{"\n"}{end}'
```

## Cross-Node Pod Communication

For pod-to-pod traffic across nodes:

- **Overlay (VXLAN)**: Encapsulate pod packet in UDP/VXLAN, send to destination node, decapsulate. No router changes needed.
- **BGP (Calico native)**: Nodes advertise pod CIDR routes to physical routers. No encapsulation overhead.
- **eBPF (Cilium)**: Bypass iptables entirely; XDP/eBPF programs in kernel handle routing.

## CoreDNS: DNS for Services

CoreDNS runs as a Deployment in `kube-system` and provides DNS resolution for Services.

```bash
# CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# DNS resolution format:
# <service-name>.<namespace>.svc.cluster.local
# <pod-ip-dashes>.<namespace>.pod.cluster.local

# Test DNS from a pod
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes.default.svc.cluster.local
```

Search domains injected into pod `/etc/resolv.conf`:
```
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
```

## Debugging Pod Networking

```bash
# Check pod IP
kubectl get pod <name> -o wide

# Check if pods can communicate
kubectl exec <pod1> -- ping <pod2-ip>

# Check CNI logs
journalctl -u kubelet | grep -i cni

# Inspect pod network namespace
pid=$(docker inspect --format '{{.State.Pid}}' <container>)
nsenter -t $pid -n ip addr
```

## Key Takeaways

- Every pod gets a unique cluster-wide IP; pods talk directly without NAT.
- CNI plugins implement this model: they wire up veth pairs and program routes.
- Pod CIDR, Service CIDR, and Node CIDR are three distinct IP spaces.
- Each node gets a slice of the pod CIDR; the CNI plugin manages allocation.
- VXLAN overlays add encapsulation; BGP avoids it at the cost of router configuration.
- CoreDNS provides `<service>.<namespace>.svc.cluster.local` resolution inside pods.
