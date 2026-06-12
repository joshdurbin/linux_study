# The Kubernetes API Server

## Role of kube-apiserver

The **kube-apiserver** is the central control point of the Kubernetes cluster. Every component — kubectl, scheduler, controller-manager, kubelet, kube-proxy — communicates exclusively through the API server. It is the only component that reads and writes to etcd.

Every API request passes through three sequential gates: **authentication**, **authorization**, and **admission control**.

## Authentication

Authentication answers: *who is making this request?*

Common authentication methods:

| Method | Use Case |
|--------|----------|
| X.509 client certificates | Component-to-component (kubelet, scheduler) |
| Bearer tokens (JWT) | ServiceAccount tokens for pods |
| OIDC tokens | Human users via identity provider (Okta, Google) |
| Webhook token auth | Custom external authenticator |

```bash
# Inspect a service account token (JWT)
kubectl get secret -n kube-system -o jsonpath='{.items[0].data.token}' | base64 -d

# Check your current identity
kubectl auth whoami
```

The API server uses the authenticated identity (username + groups) for authorization decisions.

## Authorization: RBAC

**Role-Based Access Control (RBAC)** is the standard authorization mode. It works with four resource types:

| Resource | Scope | Purpose |
|----------|-------|---------|
| Role | Namespace | Grant permissions within a namespace |
| ClusterRole | Cluster-wide | Grant permissions across all namespaces |
| RoleBinding | Namespace | Bind a Role or ClusterRole to a subject in a namespace |
| ClusterRoleBinding | Cluster-wide | Bind a ClusterRole to a subject cluster-wide |

```bash
# Check what a service account can do
kubectl auth can-i list pods --as system:serviceaccount:default:myapp

# View roles in a namespace
kubectl get roles,rolebindings -n default

# Describe a ClusterRole
kubectl describe clusterrole view

# Check your own permissions
kubectl auth can-i create deployments
kubectl auth can-i '*' '*'   # check if cluster-admin
```

## Admission Controllers

Admission controllers intercept requests **after** authentication and authorization but **before** the object is persisted to etcd. They can mutate or reject requests.

### Mutating Admission Webhooks
Called first. Can modify the request (e.g., inject sidecars, add labels, set default values).

### Validating Admission Webhooks
Called after mutation. Can only approve or reject (cannot modify).

Built-in admission controllers:

```bash
# Common built-in controllers:
# LimitRanger:     enforce default/max resource limits
# ResourceQuota:   enforce namespace-level resource quotas
# NamespaceLifecycle: prevent operations in terminating namespaces
# PodSecurity:     enforce Pod Security Standards (replaces PodSecurityPolicy)

# Check active admission plugins (on control plane node)
kube-apiserver --help | grep enable-admission-plugins
```

## API Groups and Versions

The API is organized into groups and versions:

```bash
# Core group (no group name): /api/v1
kubectl get --raw /api/v1 | jq '.resources[].name'

# Named groups: /apis/<group>/<version>
kubectl get --raw /apis/apps/v1 | jq '.resources[].name'
kubectl get --raw /apis/batch/v1 | jq '.resources[].name'

# List all API groups
kubectl api-versions

# List all resource types
kubectl api-resources
```

Common groups:

| Group | Resources |
|-------|-----------|
| core (/api/v1) | pods, services, configmaps, secrets, nodes |
| apps/v1 | deployments, replicasets, daemonsets, statefulsets |
| batch/v1 | jobs, cronjobs |
| networking.k8s.io/v1 | ingresses, networkpolicies |
| rbac.authorization.k8s.io/v1 | roles, clusterroles, rolebindings |

## Audit Logging

The API server can record every request for security and compliance:

```bash
# View audit log (if configured)
cat /var/log/kubernetes/audit.log | jq '.'
# Each entry includes: user, verb, resource, namespace, timestamp, response code
```

## Key Takeaways

- All requests go through: authentication → authorization (RBAC) → admission → etcd.
- Authentication establishes identity; RBAC grants permissions.
- RBAC: Roles/ClusterRoles define permissions; Bindings attach them to subjects.
- Mutating webhooks run before validating webhooks; both can reject requests.
- The API is versioned and grouped; explore with `kubectl api-resources` and `--raw`.
- Audit logging records every API operation for compliance and forensics.
