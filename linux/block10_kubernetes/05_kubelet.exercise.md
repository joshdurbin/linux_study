# Exercise: The kubelet

Complete the following tasks. Save your notes to `~/practice/kubelet_notes.txt`.

## Task 1 — Document kubelet Responsibilities

```bash
mkdir -p ~/practice
cat > ~/practice/kubelet_notes.txt << 'EOF'
kubelet Notes
==============
kubelet is the node agent running on every Kubernetes node.
Responsibilities:
  - Watch API server for pods assigned to this node (via spec.nodeName)
  - Call container runtime (via CRI) to create/stop containers
  - Run liveness/readiness/startup probes
  - Report pod and container status back to API server
  - Serve node metrics (port 10250)
  - Manage static pods from /etc/kubernetes/manifests/

Pod Lifecycle Phases
---------------------
Pending     - pod created in etcd, containers not yet started
             (waiting for image pull, resource availability)
Running     - at least one container is running or starting
Succeeded   - all containers exited with code 0
Failed      - at least one container exited with non-zero code
Unknown     - node not reporting (network partition, node down)

Container Runtime Interface (CRI)
-----------------------------------
kubelet → gRPC CRI → containerd → containerd-shim → runc
                   → CRI-O → runc / kata-containers

CRI abstracts the runtime; any CRI-compliant runtime works with kubelet.
Check runtime: kubectl get node -o jsonpath='{.status.nodeInfo.containerRuntimeVersion}'
EOF
```

## Task 2 — Document Static Pods

```bash
cat >> ~/practice/kubelet_notes.txt << 'EOF'

Static Pods
-----------
Static pods are defined by YAML files in a watched directory.
Default path: /etc/kubernetes/manifests/

Used for: bootstrapping the control plane (kube-apiserver, etcd, scheduler, controller-manager)
kubelet creates them directly WITHOUT going through the API server.
They appear in the API server with a node-name suffix (e.g., kube-apiserver-master).

To add a static pod: drop a YAML file in /etc/kubernetes/manifests/
To remove: delete the YAML file

Static pod path is configured in:
  /var/lib/kubelet/config.yaml → staticPodPath: /etc/kubernetes/manifests
EOF
```

## Task 3 — Document Health Probes

```bash
cat >> ~/practice/kubelet_notes.txt << 'EOF'

Health Probes
--------------
liveness probe:
  Failure action: RESTART the container
  Use case: detect deadlock, hung process, or crashed app
  Types: httpGet, tcpSocket, exec (command exit code)

readiness probe:
  Failure action: REMOVE from Service endpoint slice (traffic stops)
  Pod stays running; just not in the load balancer rotation
  Use case: app starting up, or temporarily overloaded

startup probe:
  Runs INSTEAD of liveness during startup period
  Failure action: restart container
  Use case: apps with slow startup (prevent premature liveness restarts)
  Once startup probe succeeds, liveness takes over

Key fields:
  initialDelaySeconds  - wait before first probe
  periodSeconds        - how often to probe
  failureThreshold     - how many failures before action
  successThreshold     - how many successes to declare healthy (readiness)
EOF
```

## Task 4 — Note Key Configuration Files

```bash
cat >> ~/practice/kubelet_notes.txt << 'EOF'

Key kubelet Files
------------------
/var/lib/kubelet/config.yaml     - kubelet configuration (cgroupDriver, clusterDNS, etc.)
/etc/kubernetes/kubelet.conf     - kubeconfig for API server authentication
/etc/kubernetes/manifests/       - static pod YAML files
/var/lib/kubelet/pods/           - per-pod runtime data

Commands:
  systemctl status kubelet        - check kubelet service status
  journalctl -u kubelet -f        - stream kubelet logs
  kubectl describe node <name>    - node conditions and allocated resources
  kubectl get events              - cluster events (includes pod scheduling events)

cgroup driver (must match container runtime):
  grep cgroupDriver /var/lib/kubelet/config.yaml
  grep SystemdCgroup /etc/containerd/config.toml
  Best practice: use "systemd" for both
EOF
```
