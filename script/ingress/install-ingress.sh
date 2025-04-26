#!/bin/bash
set -e

# 1. Helm 설치
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace -f ingress-values.yaml

# 1. 퍼블릭 IP 자동 조회
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

if [ -z "$PUBLIC_IP" ]; then
  echo "퍼블릭 IP 조회 실패. 스크립트를 종료합니다."
  exit 1
fi

echo "퍼블릭 IP 조회 완료: $PUBLIC_IP"

# 2. envsubst로 퍼블릭 IP 치환 + kubectl apply
envsubst < platform-ingress-template.yaml | kubectl apply -n default -f -
