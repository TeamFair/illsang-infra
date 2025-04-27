#!/bin/bash
set -ex

# 1. infra 워커 노드에 레이블 추가
kubectl label node $(kubectl get nodes --no-headers | grep -v control-plane | awk '{print $1}') node-role.kubernetes.io/infra=infra --overwrite

# 2. kube-ops-view namespace 생성
kubectl create namespace kube-ops-view || true

# 3. ServiceAccount + ClusterRoleBinding 생성
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-ops-view
  namespace: kube-ops-view
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-ops-view
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: kube-ops-view
    namespace: kube-ops-view
EOF

# 4. Deployment + Service 생성 (infra 노드에만 올라가게 nodeSelector 추가)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-ops-view
  namespace: kube-ops-view
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-ops-view
  template:
    metadata:
      labels:
        app: kube-ops-view
    spec:
      serviceAccountName: kube-ops-view
      nodeSelector:
        node-role.kubernetes.io/infra: infra
      containers:
        - name: kube-ops-view
          image: hjacobs/kube-ops-view:latest
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: kube-ops-view
  namespace: kube-ops-view
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
  selector:
    app: kube-ops-view
EOF