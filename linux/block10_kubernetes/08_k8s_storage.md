# Kubernetes Storage

## The Storage Abstraction

Kubernetes decouples the storage medium (NFS, cloud block storage, local disk) from the pod through two objects:

- **PersistentVolume (PV)**: A piece of storage in the cluster, provisioned by an admin or dynamically.
- **PersistentVolumeClaim (PVC)**: A request by a user for a specific amount and type of storage.

Pods reference PVCs, not PVs directly. This abstraction means you can change storage backends without modifying pod specs.

## PV/PVC Lifecycle

```
1. Admin creates PV (or StorageClass enables dynamic provisioning)
2. User creates PVC (specifying size, access mode, storageClass)
3. Kubernetes BINDS matching PV to PVC (1:1 binding)
4. Pod mounts the PVC as a volume
5. Pod deleted → PVC persists (data not lost)
6. PVC deleted → PV reclaim policy determines what happens
```

## Access Modes

| Mode | Description |
|------|-------------|
| ReadWriteOnce (RWO) | Mounted read-write by one node |
| ReadOnlyMany (ROX) | Mounted read-only by many nodes |
| ReadWriteMany (RWX) | Mounted read-write by many nodes (NFS, CephFS) |
| ReadWriteOncePod (RWOP) | Mounted by exactly one pod (K8s 1.22+) |

Block storage (EBS, GCE PD) supports only RWO. Network filesystems (NFS, CephFS) support RWX.

## Reclaim Policies

| Policy | Behavior When PVC is Deleted |
|--------|------------------------------|
| **Retain** | PV kept, data preserved, manual cleanup required |
| **Delete** | PV and underlying storage deleted automatically |
| **Recycle** | (deprecated) wipe and make available again |

Production recommendation: `Retain` for safety, `Delete` for ephemeral dev environments.

## StorageClasses and Dynamic Provisioning

A **StorageClass** defines how storage should be provisioned. When a PVC requests a StorageClass, Kubernetes automatically creates the PV — no admin intervention needed.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

```bash
# List storage classes
kubectl get storageclass

# Mark a storage class as default
kubectl patch storageclass gp2 -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## CSI (Container Storage Interface)

**CSI** is the standard interface for storage vendors to write Kubernetes plugins without modifying the Kubernetes core. A CSI driver consists of:

- **Controller plugin**: creates/deletes volumes, attaches/detaches from nodes
- **Node plugin**: mounts/unmounts volumes on the node

```bash
# View installed CSI drivers
kubectl get csidrivers
kubectl get csinode
```

Popular CSI drivers: AWS EBS CSI, GCE PD CSI, Azure Disk CSI, Longhorn, Rook-Ceph.

## Volume Types

| Type | Use Case |
|------|---------|
| `emptyDir` | Scratch space; deleted when pod exits |
| `hostPath` | Access host filesystem (dangerous; avoid in production) |
| `configMap` / `secret` | Inject config/credentials as files |
| `nfs` | Shared filesystem accessible from multiple nodes |
| `persistentVolumeClaim` | Reference a PVC (the standard pattern) |
| AWS EBS, GCE PD, Azure Disk | Cloud block storage via CSI |

## StatefulSets

StatefulSets are the workload type for stateful applications. They provide:

- **Stable network identity**: `<pod-name>-<ordinal>` (e.g., postgres-0, postgres-1)
- **Stable storage**: each pod gets its own PVC via `volumeClaimTemplates`
- **Ordered startup/shutdown**: pods start 0→N and stop N→0

```yaml
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: [ "ReadWriteOnce" ]
    storageClassName: fast-ssd
    resources:
      requests:
        storage: 10Gi
```

Each StatefulSet pod gets: `data-<statefulset-name>-<ordinal>` as its PVC name.

## Key Takeaways

- PV/PVC decouple storage provisioning from pod specs — swap backends without changing pods.
- Dynamic provisioning via StorageClass eliminates manual PV creation.
- CSI is the plugin interface; cloud providers ship CSI drivers for their block storage.
- Access modes depend on the backend: block storage = RWO; NFS = RWX.
- Reclaim policy: `Retain` saves data; `Delete` removes it when PVC is deleted.
- StatefulSets provide stable pod names, DNS, and per-pod PVCs via `volumeClaimTemplates`.
