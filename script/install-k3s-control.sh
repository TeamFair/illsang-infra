#!/bin/bash
set -euxo pipefail

# 기본 패키지
if ! command -v curl >/dev/null 2>&1; then
  yum install -y curl || apt-get update && apt-get install -y curl
fi

# 시간대
timedatectl set-timezone Asia/Seoul || true

# EC2 프라이빗 IP 추출 (IMDSv1/2 둘 다 시도, 실패 시 hostname -I)
get_private_ip() {
  # IMDSv2 토큰 시도
  if TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60"); then
    curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4 || true
  fi
}
PRIVATE_IP=$(get_private_ip || true)
if [ -z "${PRIVATE_IP}" ]; then
  PRIVATE_IP=$(hostname -I | awk '{print $1}')
fi

# K3s 설치 옵션
export INSTALL_K3S_SKIP_SELINUX_RPM=true

# 이미 깔려있으면 버전 출력만
if systemctl is-active --quiet k3s; then
  k3s --version
else
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --node-ip ${PRIVATE_IP} \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --disable servicelb \
    --disable metrics-server" sh -s -
fi

# KUBECONFIG 설정(루트 + ec2-user)
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >/etc/profile.d/kubeconfig.sh
chmod 644 /etc/profile.d/kubeconfig.sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

if id ec2-user >/dev/null 2>&1; then
  mkdir -p ~ec2-user/.kube
  ln -sf /etc/rancher/k3s/k3s.yaml ~ec2-user/.kube/config
  chown -R ec2-user:ec2-user ~ec2-user/.kube
fi

# Helm 설치
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
echo 'export PATH=$PATH:/usr/local/bin' >/etc/profile.d/helm-path.sh
export PATH=$PATH:/usr/local/bin

# 상태 확인
kubectl get nodes -o wide || true
