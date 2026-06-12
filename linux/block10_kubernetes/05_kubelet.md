# The kubelet

## What Is the kubelet?

The **kubelet** is the primary node agent in Kubernetes. It runs on every node (including control plane nodes in kubeadm clusters) and is responsible for ensuring that the containers described in pod specs are running and healthy on that node.

The kubelet does not manage containers it did not create through Kubernetes — it only manages pods.

## Pod Lifecycle

```
Pending → Running → Succeeded / Failed
                 ↘ Unknown (node unreachable)
```

| Phase | Meaning |
|-------|---------|
| Pending | Pod accepted; containers not yet started (pulling image, waiting for scheduling) |
| Running | At least one container is running or starting |
| Succeeded | All containers exited with code 0 |
| Failed | At least one container exited non-zero |
| Unknown | Node not reporting status (network partition) |

## Container Runtime Interface (CRI)

The kubelet does not directly call Docker or containerd. It uses the **Container Runtime Interface (CRI)**, a gRPC API that abstracts the container runtime. Any runtime that implements CRI works with kubelet.

```
kubelet → CRI (gRPC) → containerd → containerd-shim → runc
kubelet → CRI (gRPC) → CRI-O → runc / kata-containers
```

```bash
# Check which runtime a node uses
kubectl get node <node> -o jsonpath='{.status.nodeInfo.containerRuntimeVersion}'
# e.g., "containerd://1.7.2"
```

## Static Pods

Static pods are defined by YAML files in a directory on the node (default: `/etc/kubernetes/manifests/`). The kubelet watches this directory and creates the pods directly — no API server interaction is needed to create them.

**This is how the Kubernetes control plane bootstraps itself.** The API server, etcd, scheduler, and controller-manager are all static pods on the control plane node.

```bash
# View static pod manifests (on control plane node)
ls /etc/kubernetes/manifests/
# kube-apiserver.yaml  etcd.yaml  kube-controller-manager.yaml  kube-scheduler.yaml

# Static pods appear in the API server with node name suffix
kubectl get pods -n kube-system
# e.g., kube-apiserver-controlplane
```

## Health Probes

The kubelet runs probes on behalf of containers:

| Probe | Failure Action | Use Case |
|-------|---------------|---------|
| **liveness** | Restart the container | Detect deadlock or hung process |
| **readiness** | Remove from Service endpoints | Not ready to accept traffic |
| **startup** | Restart (only during startup) | Slow-starting apps (replaces liveness during startup) |

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 20
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 5
```

## kubelet Configuration

```bash
# kubelet config file (kubeadm cluster)
cat /var/lib/kubelet/config.yaml

# kubeconfig for API server auth
cat /etc/kubernetes/kubelet.conf

# kubelet systemd unit
systemctl status kubelet
journalctl -u kubelet -f    # stream logs

# Key config options:
# cgroupDriver: systemd (must match container runtime)
# clusterDNS: CoreDNS service IP
# staticPodPath: /etc/kubernetes/manifests
```

## cgroup Driver Alignment

The kubelet's `cgroupDriver` must match the container runtime's cgroup driver. Mismatch causes pods to fail to start.

```bash
# Check kubelet cgroup driver
grep cgroupDriver /var/lib/kubelet/config.yaml

# Check containerd cgroup driver
grep SystemdCgroup /etc/containerd/config.toml
```

Modern best practice: use `systemd` for both, since systemd manages the host cgroup hierarchy.

## Key Takeaways

- kubelet is the node agent; it manages pods assigned to its node.
- Pod phases: Pending → Running → Succeeded/Failed.
- kubelet talks to the container runtime via CRI (gRPC API), not directly.
- Static pods in `/etc/kubernetes/manifests/` bootstrap the control plane.
- Liveness probes restart failed containers; readiness probes gate Service traffic.
- `cgroupDriver` must match between kubelet and container runtime.
- Debug with `journalctl -u kubelet` and `kubectl describe pod`.
