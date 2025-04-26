#!/bin/bash
set -ex

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

