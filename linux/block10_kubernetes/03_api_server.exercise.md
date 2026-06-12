# Exercise: The Kubernetes API Server

Complete the following tasks. Save your notes to `~/practice/apiserver_notes.txt`.

## Task 1 — Document the Three-Gate Request Flow

```bash
mkdir -p ~/practice
cat > ~/practice/apiserver_notes.txt << 'EOF'
Kubernetes API Server Notes
============================

Request Processing Pipeline
------------------------------
Every request through kube-apiserver passes three gates in order:

Gate 1: Authentication — WHO is making this request?
  Methods:
    X.509 client certificates  (kubelet, scheduler, controller-manager)
    Bearer tokens / JWT         (ServiceAccounts in pods)
    OIDC tokens                 (human users via Okta/Google/Azure AD)
    Webhook token auth          (custom external authenticator)
  Result: identity (username + list of groups)
  Anonymous: if all authn fails and anonymous auth is enabled, uses system:anonymous

Gate 2: Authorization — CAN this identity do this action?
  Standard mode: RBAC (Role-Based Access Control)
  Decision: ALLOW or DENY based on Role/ClusterRole bindings
  Check: kubectl auth can-i <verb> <resource>

Gate 3: Admission Control — Is this request valid/allowed?
  Mutating webhooks (run first, can modify request)
  Validating webhooks (run after mutation, can only reject)
  Built-in controllers: LimitRanger, ResourceQuota, NamespaceLifecycle, PodSecurity
  Result: object written to etcd if all admission controllers pass
EOF
```

## Task 2 — Document RBAC Resources

```bash
cat >> ~/practice/apiserver_notes.txt << 'EOF'

RBAC Resources
---------------
Role:               permissions within a single namespace
ClusterRole:        permissions across all namespaces (or non-namespaced resources)
RoleBinding:        attach Role or ClusterRole to a subject in a namespace
ClusterRoleBinding: attach ClusterRole to a subject cluster-wide

Subject types: User, Group, ServiceAccount

Example Role (allow read pods in default namespace):
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    namespace: default
    name: pod-reader
  rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]

Example RoleBinding:
  subjects:
  - kind: ServiceAccount
    name: myapp
    namespace: default
  roleRef:
    kind: Role
    name: pod-reader
    apiGroup: rbac.authorization.k8s.io
EOF
```

## Task 3 — Document API Groups

```bash
cat >> ~/practice/apiserver_notes.txt << 'EOF'

API Groups and Versions
------------------------
Core group:          /api/v1        (pods, services, configmaps, secrets, nodes)
apps:                /apis/apps/v1  (deployments, replicasets, daemonsets, statefulsets)
batch:               /apis/batch/v1 (jobs, cronjobs)
networking.k8s.io:   /apis/networking.k8s.io/v1 (ingresses, networkpolicies)
rbac.auth.k8s.io:    /apis/rbac.authorization.k8s.io/v1

Explore:
  kubectl api-resources     - list all resource types with API groups
  kubectl api-versions      - list all group/version pairs
  kubectl get --raw /api/v1 - raw API discovery
EOF
```

## Task 4 — Check kubectl Context and Permissions (if available)

```bash
echo "" >> ~/practice/apiserver_notes.txt
echo "kubectl context:" >> ~/practice/apiserver_notes.txt
kubectl config current-context 2>/dev/null >> ~/practice/apiserver_notes.txt || echo "(kubectl not configured)" >> ~/practice/apiserver_notes.txt

echo "" >> ~/practice/apiserver_notes.txt
echo "Can-I checks:" >> ~/practice/apiserver_notes.txt
kubectl auth can-i list pods 2>/dev/null >> ~/practice/apiserver_notes.txt || echo "(cluster not available)" >> ~/practice/apiserver_notes.txt
```
