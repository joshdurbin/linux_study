# Exercise: etcd Deep Dive

Complete the following tasks. Save your notes to `~/practice/etcd_notes.txt`.

## Task 1 — Document Raft Consensus and Quorum

```bash
mkdir -p ~/practice
cat > ~/practice/etcd_notes.txt << 'EOF'
etcd Deep Dive Notes
=====================
etcd is a distributed key-value store used as Kubernetes' sole persistent data store.
All cluster state lives in etcd: pods, services, secrets, configmaps, RBAC, etc.

Raft Consensus Algorithm
--------------------------
Raft ensures all nodes agree on data despite failures.

Steps:
  1. Leader election: one node becomes leader (handles all writes)
  2. Log replication: leader replicates entries to followers
  3. Quorum commit: write committed when majority of nodes acknowledge
  4. Failure recovery: followers detect missing heartbeat, elect new leader

Quorum = floor(N/2) + 1

Cluster sizes and fault tolerance:
  3 nodes: quorum=2, tolerates 1 failure  ← standard production
  5 nodes: quorum=3, tolerates 2 failures ← large production clusters
  7 nodes: quorum=4, tolerates 3 failures

Why odd numbers?
  4-node cluster requires quorum of 3 (same as 3-node) but uses an extra machine.
  Odd numbers give the best fault tolerance per machine.
EOF
```

## Task 2 — Document etcdctl Commands

```bash
cat >> ~/practice/etcd_notes.txt << 'EOF'

etcdctl Key Commands (API v3)
-------------------------------
export ETCDCTL_API=3

etcdctl put /key value                      # write a key
etcdctl get /key                            # read a key
etcdctl del /key                            # delete a key
etcdctl watch /key                          # stream changes to a key
etcdctl get /prefix --prefix --keys-only    # list keys with prefix
etcdctl member list                         # show cluster members
etcdctl endpoint health                     # check all endpoints
etcdctl endpoint status --write-out=table   # show leader/version info

Backup and restore:
etcdctl snapshot save /backup/snapshot.db   # take backup
etcdctl snapshot status /backup/snapshot.db # verify backup
etcdctl snapshot restore /backup/snapshot.db --data-dir=/var/lib/etcd-new
EOF
```

## Task 3 — Document Kubernetes Data Layout in etcd

```bash
cat >> ~/practice/etcd_notes.txt << 'EOF'

Kubernetes Keys in etcd (under /registry/)
--------------------------------------------
/registry/pods/<namespace>/<pod-name>
/registry/services/specs/<namespace>/<service-name>
/registry/deployments/<namespace>/<deployment-name>
/registry/configmaps/<namespace>/<name>
/registry/secrets/<namespace>/<name>
/registry/namespaces/<name>
/registry/nodes/<node-name>

Data format: protobuf (not plain JSON)
To decode: use kubectl or etcdhelper tool

Inspect K8s data:
  etcdctl get /registry/pods --prefix --keys-only
  etcdctl get /registry/namespaces/default
EOF
```

## Task 4 — Calculate Quorum for Different Cluster Sizes

```bash
cat >> ~/practice/etcd_notes.txt << 'EOF'

Quorum Calculations
--------------------
Formula: quorum = floor(N/2) + 1

N=1: quorum=1, can lose 0 nodes (no HA)
N=3: quorum=2, can lose 1 node
N=4: quorum=3, can lose 1 node (no better than N=3!)
N=5: quorum=3, can lose 2 nodes
N=6: quorum=4, can lose 2 nodes (no better than N=5!)
N=7: quorum=4, can lose 3 nodes

Rule: always use odd cluster sizes for etcd.
EOF
```

## Task 5 — Check if etcdctl is Available

```bash
echo "" >> ~/practice/etcd_notes.txt
echo "etcdctl availability:" >> ~/practice/etcd_notes.txt
if command -v etcdctl &>/dev/null; then
  etcdctl version >> ~/practice/etcd_notes.txt
else
  echo "etcdctl not found (typical in worker node / student environment)" >> ~/practice/etcd_notes.txt
fi
```
