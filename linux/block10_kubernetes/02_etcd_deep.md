# etcd Deep Dive

## What Is etcd?

**etcd** is a distributed, strongly consistent key-value store developed at CoreOS and now maintained by the CNCF. Kubernetes uses etcd as its sole persistent data store — all cluster state (pods, services, configmaps, secrets, deployments, RBAC rules) lives in etcd.

## Raft Consensus

etcd uses the **Raft** consensus algorithm to ensure that all nodes in the cluster agree on the same data even in the face of node failures.

### How Raft Works

1. **Leader election**: One node is elected leader. The leader handles all writes.
2. **Log replication**: The leader appends new entries to its log and replicates them to followers.
3. **Quorum**: A write is considered committed once a **majority** of nodes acknowledge it.
4. **Leader failure**: Followers detect the missing heartbeat and elect a new leader.

Raft guarantees that there is at most one leader at any time, preventing split-brain.

## Why Odd Node Counts?

Quorum = floor(N/2) + 1 nodes must agree for a write to succeed.

| Cluster Size | Quorum | Tolerable Failures |
|-------------|--------|-------------------|
| 1           | 1      | 0                 |
| 3           | 2      | 1                 |
| 5           | 3      | 2                 |
| 7           | 4      | 3                 |

Even-sized clusters offer no better fault tolerance than the odd size below them: a 4-node cluster still requires 3 nodes (same as a 3-node cluster), but uses an extra machine.

## etcdctl Commands

```bash
# Set the API version
export ETCDCTL_API=3

# Connect to a local etcd
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Basic key operations
etcdctl put /test/key1 "value1"
etcdctl get /test/key1
etcdctl del /test/key1

# Watch for changes (streams updates)
etcdctl watch /test/key1

# Get with prefix (list all keys under a path)
etcdctl get /registry/pods --prefix --keys-only
```

## Kubernetes Data in etcd

All K8s objects are stored under `/registry/`:

```bash
# List all pod keys
etcdctl get /registry/pods --prefix --keys-only

# Get a specific pod (data is protobuf-encoded, not plain JSON)
etcdctl get /registry/pods/default/mypod

# Other key prefixes:
# /registry/services/specs/
# /registry/deployments/
# /registry/configmaps/
# /registry/secrets/
# /registry/namespaces/
```

## Backup and Restore

etcd backup is **critical** for disaster recovery — it is the only copy of all cluster state.

```bash
# Take a snapshot
etcdctl snapshot save /backup/etcd-snapshot-$(date +%Y%m%d).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify snapshot
etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table

# Restore from snapshot (stops cluster first)
etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restore
```

## etcd in Kubernetes

```bash
# View the etcd pod on a kubeadm cluster
kubectl get pod -n kube-system etcd-<node-name> -o yaml

# etcd data directory
ls /var/lib/etcd/

# etcd health check
etcdctl endpoint health
etcdctl endpoint status --write-out=table
```

## Key Takeaways

- etcd is the single source of truth for all Kubernetes cluster state.
- Raft provides strong consistency: every write is acknowledged by a quorum before committing.
- Use odd-numbered clusters (3, 5, 7); 3 is standard, 5 is recommended for large production clusters.
- etcdctl v3 API is the standard; always set `ETCDCTL_API=3`.
- Back up etcd regularly with `etcdctl snapshot save` — losing etcd means losing the cluster.
- Kubernetes data is stored under `/registry/` in protobuf format.
