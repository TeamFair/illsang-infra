#!/bin/bash
# install-metrics-server-helm.sh
set -euxo pipefail

# ===== 설정 =====
CHART_VERSION=""                 # 빈 값이면 최신 차트 사용. 예: "3.13.0"
APP_IMAGE_TAG=""                 # 빈 값이면 차트 기본 이미지 태그 사용. 예: "v0.8.0"
INSECURE_TLS="true"              # kubelet 인증서 이슈 회피(테스트/개인 클러스터 권장)
REQ_CPU="50m"; REQ_MEM="50Mi"
LIM_CPU="200m"; LIM_MEM="200Mi"

# ===== 준비 =====
# helm 경로 보장
if ! command -v helm >/dev/null 2>&1 && [ -x /usr/local/bin/helm ]; then
  export PATH="/usr/local/bin:$PATH"
fi

# ===== 설치/업그레이드 =====
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ || true
helm repo update

ARGS=(--kubelet-preferred-address-types=InternalIP --kubelet-use-node-status-port)
if [ "$INSECURE_TLS" = "true" ]; then
  ARGS+=(--kubelet-insecure-tls)
fi

HELM_SET=(
  --set "args[0]=${ARGS[0]}"
  --set "args[1]=${ARGS[1]}"
  --set "resources.requests.cpu=${REQ_CPU}"
  --set "resources.requests.memory=${REQ_MEM}"
  --set "resources.limits.cpu=${LIM_CPU}"
  --set "resources.limits.memory=${LIM_MEM}"
)

if [ "$INSECURE_TLS" = "true" ]; then
  HELM_SET+=(--set "args[2]=${ARGS[2]}")
fi

# 버전 고정(선택)
if [ -n "$CHART_VERSION" ]; then
  HELM_SET+=(--version "$CHART_VERSION")
fi
if [ -n "$APP_IMAGE_TAG" ]; then
  HELM_SET+=(--set "image.tag=${APP_IMAGE_TAG}")
fi

helm upgrade --install metrics-server metrics-server/metrics-server \
  -n kube-system --create-namespace \
  "${HELM_SET[@]}"

# ===== 검증 =====
kubectl -n kube-system rollout status deploy/metrics-server

# APIService Ready 대기(최대 90초)
for i in {1..18}; do
  st=$(kubectl get apiservice v1beta1.metrics.k8s.io -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' || true)
  [ "$st" = "True" ] && echo "metrics.k8s.io APIService Available" && break
  echo "Waiting for metrics APIService... ($i/18)"; sleep 5
done

# 샘플 출력(없어도 무방)
kubectl top nodes || true
kubectl top pods -A || true

echo "metrics-server 설치/검증 완료"
