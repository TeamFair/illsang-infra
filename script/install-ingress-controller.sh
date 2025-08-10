#!/usr/bin/env bash
set -euo pipefail

NS=ingress-nginx
MANIFEST=https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

echo "[1/7] Apply upstream manifest"
kubectl apply -f "$MANIFEST"

echo "[2/7] Wait namespace & controller appear"
# 네임스페이스가 생길 때까지 대기
for i in {1..30}; do
  kubectl get ns "$NS" >/dev/null 2>&1 && break
  sleep 2
done

# Deployment 생성 대기 (존재 보장)
for i in {1..60}; do
  kubectl -n "$NS" get deploy/ingress-nginx-controller >/dev/null 2>&1 && break
  sleep 2
done

echo "[3/7] Pin controller to control-plane (nodeSelector + tolerations)"
kubectl -n "$NS" patch deploy ingress-nginx-controller --type merge -p '{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": { "node-role.kubernetes.io/control-plane": "true" },
        "tolerations": [
          {"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"},
          {"key":"node-role.kubernetes.io/master","operator":"Exists","effect":"NoSchedule"}
        ]
      }
    }
  }
}'

echo "[4/7] Single replica"
kubectl -n "$NS" scale deploy ingress-nginx-controller --replicas=1

echo "[5/7] Wait for Service to exist, then switch to NodePort"
for i in {1..60}; do
  kubectl -n "$NS" get svc ingress-nginx-controller >/dev/null 2>&1 && break
  sleep 2
done
kubectl -n "$NS" patch svc ingress-nginx-controller -p '{
  "spec":{"type":"NodePort","ports":[
    {"name":"http","port":80,"nodePort":30080},
    {"name":"https","port":443,"nodePort":30443}
  ]}
}'

echo "[6/7] Rollout wait"
kubectl -n "$NS" rollout status deploy/ingress-nginx-controller --timeout=180s || true

echo "[7/7] Check"
kubectl -n "$NS" get pods -o wide
kubectl -n "$NS" get svc ingress-nginx-controller
kubectl -n "$NS" get ep ingress-nginx-controller-admission
