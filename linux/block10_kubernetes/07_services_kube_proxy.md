# Services and kube-proxy

## What Is a Kubernetes Service?

A **Service** provides a stable virtual IP (the **ClusterIP**) and DNS name that fronts a dynamic set of pods. As pods come and go, the Service's IP stays constant. kube-proxy programs the kernel to route traffic from the ClusterIP to the current set of healthy pod IPs.

## Service Types

| Type | Access | How It Works |
|------|--------|-------------|
| **ClusterIP** | Inside cluster only | Virtual IP routed to pods via iptables/IPVS |
| **NodePort** | External via `<nodeIP>:<port>` | Opens a port on every node; traffic DNAT'd to ClusterIP |
| **LoadBalancer** | External via cloud LB | Cloud provider provisions a load balancer that forwards to NodePort |
| **ExternalName** | DNS CNAME only | Returns a CNAME record; no proxying |

## ClusterIP Routing via iptables

kube-proxy watches Services and EndpointSlices. For every ClusterIP service, it programs iptables DNAT rules:

```bash
# View kube-proxy's iptables rules for a service
sudo iptables -t nat -L KUBE-SERVICES -n -v
# Look for: KUBE-SVC-XXXXXXXXXXXXXXXX  tcp  dpt:<port>

# See the DNAT to pod IPs
sudo iptables -t nat -L KUBE-SVC-XXXXXXXXXXXXXXXX -n -v
# KUBE-SEP-XXX  (each SEP = service endpoint)

sudo iptables -t nat -L KUBE-SEP-XXXXXXXXXXXXXXXX -n -v
# DNAT: to:10.244.0.5:8080
```

The packet flow for a ClusterIP request:

```
client pod
  ↓ packet to ClusterIP:port
iptables KUBE-SERVICES chain
  ↓ match service ClusterIP
iptables KUBE-SVC-XXX chain (randomly selects one endpoint)
  ↓
iptables KUBE-SEP-XXX chain (DNAT: rewrites dst to pod IP:port)
  ↓
pod IP (routed via CNI)
```

## IPVS Mode

kube-proxy can use IPVS (IP Virtual Server) instead of iptables for better performance at scale:

```bash
# Check kube-proxy mode
kubectl get configmap kube-proxy -n kube-system -o yaml | grep mode

# IPVS provides more load balancing algorithms:
# rr (round-robin), lc (least connection), sh (source hash)
ipvsadm -ln   # view IPVS rules (if mode=ipvs)
```

## Endpoint Slices

Before EndpointSlices, a single `Endpoints` object listed all pod IPs. At scale (1000s of pods), updating this single object caused thundering herd writes to etcd. **EndpointSlice** splits the list into chunks of ≤100 endpoints per slice, drastically reducing API server load.

```bash
kubectl get endpointslices -n default
kubectl describe endpointslice <name>
```

## NodePort Services

```bash
# Create a NodePort service
kubectl expose deployment myapp --type=NodePort --port=80

# Find the assigned port
kubectl get svc myapp
# NAME    TYPE       CLUSTER-IP     PORT(S)
# myapp   NodePort   10.96.82.33    80:31045/TCP

# Access from outside
curl http://<any-node-ip>:31045
```

iptables chain: `KUBE-NODEPORTS` → `KUBE-SVC-XXX` → `KUBE-SEP-XXX` → pod

## Headless Services

Setting `spec.clusterIP: None` creates a **headless service**. DNS returns pod IPs directly instead of a ClusterIP — useful for StatefulSets where you want to address individual pods.

```bash
# Headless service DNS returns all pod IPs
kubectl run dns-test --image=busybox --rm -it -- nslookup myheadless-service
# Returns: multiple A records (one per pod)
```

## Key Takeaways

- ClusterIP is a virtual IP that never changes, even as pods are replaced.
- kube-proxy programs iptables DNAT rules: ClusterIP → random pod IP.
- iptables chains: KUBE-SERVICES → KUBE-SVC-XXX (load balance) → KUBE-SEP-XXX (DNAT).
- IPVS mode is more performant than iptables for large clusters.
- NodePort opens a port on every node; LoadBalancer uses cloud infrastructure.
- EndpointSlices replaced Endpoints for better scalability.
- Headless services (`clusterIP: None`) return pod IPs directly via DNS.
