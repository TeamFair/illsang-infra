#!/bin/bash
set -euxo pipefail

# 시간대
timedatectl set-timezone Asia/Seoul || true

# EC2 프라이빗 IP
get_private_ip() {
  if TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 60"); then
    curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4 || true
  fi
}
PRIVATE_IP=$(get_private_ip || true)
[ -z "${PRIVATE_IP:-}" ] && PRIVATE_IP=$(hostname -I | awk '{print $1}')

export INSTALL_K3S_SKIP_SELINUX_RPM=true

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

# KUBECONFIG
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' | tee /etc/profile.d/kubeconfig.sh >/dev/null
chmod 644 /etc/profile.d/kubeconfig.sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# ec2-user에 kubeconfig 심볼릭 링크
if id ec2-user >/dev/null 2>&1; then
  mkdir -p ~ec2-user/.kube
  ln -sf /etc/rancher/k3s/k3s.yaml ~ec2-user/.kube/config
  chown -R ec2-user:ec2-user ~ec2-user/.kube
fi

kubectl get nodes -o wide || true
