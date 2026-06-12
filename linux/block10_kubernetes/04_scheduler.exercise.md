# Exercise: The Kubernetes Scheduler

Complete the following tasks. Save your notes to `~/practice/scheduler_notes.txt`.

## Task 1 — Document the Scheduling Decision Flow

```bash
mkdir -p ~/practice
cat > ~/practice/scheduler_notes.txt << 'EOF'
Kubernetes Scheduler Notes
===========================

Scheduling Workflow (for each unbound pod)
--------------------------------------------
Step 1: Watch API server for pods where spec.nodeName is empty
Step 2: FILTER phase — eliminate nodes that fail hard constraints
Step 3: SCORE phase  — rank remaining nodes by soft preferences
Step 4: SELECT       — pick highest-scored node (random tiebreak)
Step 5: BIND         — write spec.nodeName to the pod via API server
Step 6: kubelet on selected node watches, picks up pod, starts containers

FILTER plugins (node must pass all of these):
  NodeResourcesFit       - enough CPU, memory, ephemeral storage
  NodeSelector           - matches pod's nodeSelector labels
  TaintToleration        - pod tolerates all node taints
  NodeAffinity           - matches requiredDuringScheduling rules
  PodAffinity/AntiAffin  - respects inter-pod co-location constraints
  VolumeBinding          - node satisfies PVC volume requirements
  NodeUnschedulable      - node is not cordoned (kubectl cordon)

SCORE plugins (higher score = more preferred):
  LeastAllocated         - prefer nodes with more free resources
  NodeAffinity           - prefer nodes matching preferredDuringScheduling
  InterPodAffinity       - prefer nodes near/away from specific pods
  ImageLocality          - prefer nodes that already have the image cached
  PodTopologySpread      - spread pods across zones and nodes
EOF
```

## Task 2 — Document Taints and Tolerations

```bash
cat >> ~/practice/scheduler_notes.txt << 'EOF'

Taints and Tolerations
------------------------
Taints mark nodes to repel pods.
Tolerations allow pods to be scheduled on tainted nodes.

Taint effects:
  NoSchedule     - don't schedule new pods (existing pods stay)
  PreferNoSchedule - try to avoid scheduling here
  NoExecute      - evict existing pods that don't tolerate this

Commands:
  kubectl taint nodes <node> key=value:NoSchedule     # add taint
  kubectl taint nodes <node> key=value:NoSchedule-    # remove taint

Use cases:
  - Dedicated GPU nodes (taint: dedicated=gpu:NoSchedule)
  - Control plane nodes (taint: node-role.kubernetes.io/control-plane:NoSchedule)
  - Nodes under maintenance (taint: node.kubernetes.io/unschedulable:NoSchedule)
EOF
```

## Task 3 — Document nodeAffinity vs nodeSelector

```bash
cat >> ~/practice/scheduler_notes.txt << 'EOF'

nodeSelector vs nodeAffinity
------------------------------
nodeSelector:
  Simple label match, hard requirement only.
  spec.nodeSelector: { disktype: ssd }

nodeAffinity:
  More expressive (In, NotIn, Exists, Gt, Lt operators).
  Two types:
    requiredDuringSchedulingIgnoredDuringExecution:  hard constraint
    preferredDuringSchedulingIgnoredDuringExecution: soft preference (with weight)

podAffinity / podAntiAffinity:
  Schedule relative to other pods (same zone, different node, etc.)
  Example: spread frontend pods across zones
EOF
```

## Task 4 — Note Debugging Commands

```bash
cat >> ~/practice/scheduler_notes.txt << 'EOF'

Debugging Scheduling Failures
--------------------------------
kubectl describe pod <name>        # check Events section for filter failures
kubectl get events --sort-by='.lastTimestamp'  # cluster-wide events
kubectl top nodes                  # current resource utilization
kubectl describe node <node>       # allocatable vs allocated resources
kubectl get nodes -o wide          # node status and roles

Common failure messages:
  "Insufficient cpu"              - NodeResourcesFit filter failed
  "node(s) had taint..."          - TaintToleration filter failed
  "0/3 nodes are available"       - all nodes filtered out
  "didn't match node selector"    - NodeSelector filter failed
EOF
```
