# The Kubernetes Scheduler

## What Does the Scheduler Do?

The **kube-scheduler** watches for pods that have no `nodeName` set (unscheduled pods). For each such pod, it runs a two-phase algorithm to select the best node, then writes the chosen node name back to the pod spec via the API server.

## Scheduling Workflow

```
1. Watch API server for pods with spec.nodeName == ""
2. Filter phase: remove nodes that cannot run this pod (hard constraints)
3. Score phase:  rank remaining nodes (soft preferences)
4. Bind: write spec.nodeName = <chosen node> to API server
5. kubelet on chosen node picks up the pod and starts containers
```

## Filter Phase (Predicates)

Every node is evaluated against all active filter plugins. A node that fails any filter is excluded.

| Plugin | What It Checks |
|--------|---------------|
| NodeResourcesFit | Node has enough CPU, memory, and ephemeral storage |
| NodeName | Matches `spec.nodeName` if set manually |
| NodeSelector | Matches `spec.nodeSelector` labels |
| TaintToleration | Pod tolerates all node taints |
| PodAffinity / PodAntiAffinity | Co-location or separation constraints |
| VolumeBinding | Node can satisfy PVC requirements |
| NodeUnschedulable | Node is not cordoned |

## Score Phase (Priorities)

Remaining nodes are each scored 0–100 by score plugins; scores are weighted and summed.

| Plugin | Behavior |
|--------|---------|
| LeastAllocated | Prefer nodes with more free resources |
| NodeAffinity | Prefer nodes matching `preferredDuringScheduling` rules |
| InterPodAffinity | Prefer nodes near/away from other pods |
| ImageLocality | Prefer nodes that already have the container image |
| PodTopologySpread | Spread pods evenly across zones/nodes |

## Node Selection: nodeSelector and nodeAffinity

```yaml
# Simple label match (hard requirement)
spec:
  nodeSelector:
    disktype: ssd

# Advanced affinity (hard + soft)
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values: [us-east-1a, us-east-1b]
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values: [ssd]
```

## Taints and Tolerations

**Taints** mark a node to repel pods. **Tolerations** allow a pod to be scheduled on a tainted node.

```bash
# Add a taint to a node
kubectl taint nodes node1 dedicated=gpu:NoSchedule

# Remove a taint
kubectl taint nodes node1 dedicated=gpu:NoSchedule-

# List node taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

Toleration in pod spec:

```yaml
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
```

Taint effects:
- `NoSchedule` — do not schedule new pods here
- `PreferNoSchedule` — try to avoid scheduling here
- `NoExecute` — evict existing pods that don't tolerate this

## Pod Priority and Preemption

If no node can satisfy a high-priority pod, the scheduler can **preempt** (evict) lower-priority pods to make room.

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
```

## Debugging Scheduling Failures

```bash
# Why is a pod pending?
kubectl describe pod <pod-name>
# Look for: "Events:" section — scheduler will log filter failures

# List nodes and their resource usage
kubectl top nodes
kubectl describe node <node-name>

# Check node conditions
kubectl get nodes -o wide
```

## Key Takeaways

- The scheduler only watches for pods with no `nodeName` and writes the binding.
- Filter phase removes ineligible nodes (hard constraints); score phase ranks eligible nodes.
- `nodeSelector` and `nodeAffinity` control which nodes a pod can/prefers to land on.
- Taints mark nodes to repel pods; tolerations override that repulsion for specific pods.
- Scheduling failures show up in `kubectl describe pod` under Events.
- Priority classes and preemption handle resource contention for critical workloads.
