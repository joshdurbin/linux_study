# Exercise: Kubernetes Storage

Complete the following tasks. Save your notes to `~/practice/storage_notes.txt`.

## Task 1 — Document PV/PVC Lifecycle

```bash
mkdir -p ~/practice
cat > ~/practice/storage_notes.txt << 'EOF'
Kubernetes Storage Notes
=========================

PV/PVC Lifecycle
-----------------
PersistentVolume (PV):
  A piece of cluster storage, provisioned by admin or dynamically.
  Has: capacity, accessMode, reclaimPolicy, storageClass, volume source.

PersistentVolumeClaim (PVC):
  A request by a user for storage.
  Has: storage request size, accessMode, storageClassName.
  Bound 1:1 to a PV.

Lifecycle steps:
  1. PV created (manually or dynamically via StorageClass)
  2. PVC created with size + access mode + storageClass
  3. K8s binds PVC to matching PV (capacity >= requested, access mode matches)
  4. Pod spec references PVC as a volume
  5. Pod deleted → PVC still exists, data preserved
  6. PVC deleted → reclaim policy determines fate of PV

Reclaim Policies:
  Retain  - PV kept, admin must manually recover/delete (DATA SAFE)
  Delete  - PV and backing storage deleted when PVC deleted (DATA LOST)
  Recycle - deprecated; wiped and re-released (use dynamic provisioning instead)

Access Modes:
  ReadWriteOnce (RWO)  - read-write, one node only (EBS, GCE PD, Azure Disk)
  ReadOnlyMany  (ROX)  - read-only, many nodes
  ReadWriteMany (RWX)  - read-write, many nodes (NFS, CephFS, Azure Files)
  ReadWriteOncePod     - read-write, exactly one pod (K8s 1.22+)
EOF
```

## Task 2 — Document Dynamic Provisioning

```bash
cat >> ~/practice/storage_notes.txt << 'EOF'

Dynamic Provisioning via StorageClass
---------------------------------------
StorageClass: defines HOW to provision storage automatically.
When a PVC requests a StorageClass, K8s creates the PV automatically.

StorageClass fields:
  provisioner:  the CSI driver or built-in provisioner
  parameters:   driver-specific settings (disk type, IOPS, etc.)
  reclaimPolicy: what happens to PV when PVC deleted (Retain or Delete)
  volumeBindingMode:
    Immediate         - provision immediately when PVC created
    WaitForFirstConsumer - wait until pod scheduled (needed for zone-aware storage)

Mark a StorageClass as default:
  kubectl patch storageclass <name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

A PVC without storageClassName uses the default StorageClass.
EOF
```

## Task 3 — Document CSI Architecture

```bash
cat >> ~/practice/storage_notes.txt << 'EOF'

CSI (Container Storage Interface)
------------------------------------
CSI = standard plugin interface for storage vendors.
Allows adding storage drivers without modifying K8s core.

CSI driver components:
  Controller plugin:  creates/deletes volumes; attach/detach to nodes
  Node plugin:        mounts/unmounts volumes on each node

Popular CSI drivers:
  aws-ebs-csi-driver     - AWS Elastic Block Store
  gce-pd-csi-driver      - GCP Persistent Disk
  azuredisk-csi-driver   - Azure Disk
  rook-ceph              - Ceph distributed storage
  longhorn               - Rancher Longhorn distributed block storage

kubectl get csidrivers      - list installed CSI drivers
kubectl get csinode         - per-node CSI driver info
kubectl get storageclass    - available storage classes
EOF
```

## Task 4 — Document StatefulSet Storage

```bash
cat >> ~/practice/storage_notes.txt << 'EOF'

StatefulSets and Stable Storage
---------------------------------
StatefulSet provides:
  Stable pod names:   <name>-0, <name>-1, <name>-2
  Stable DNS:         <pod-name>.<headless-service>.<ns>.svc.cluster.local
  Stable storage:     each pod gets its own PVC that persists pod restarts

volumeClaimTemplates: defines the PVC template for each pod.
PVC naming: <template-name>-<statefulset-name>-<ordinal>
  e.g., data-postgres-0, data-postgres-1

Ordered startup: pod 0 must be Running before pod 1 starts.
Ordered shutdown: pod N-1 deleted before pod N-2.

Use cases: databases (PostgreSQL, MySQL, Cassandra), message queues (Kafka)
EOF
```
