#!/bin/bash
set -ex

# 입력 받기
read -p "Enter MASTER_PUBLIC_IP: " MASTER_PUBLIC_IP
read -p "Enter K3S_TOKEN: " K3S_TOKEN

# 기존 설치 제거 (있다면)
sudo /usr/local/bin/k3s-agent-uninstall.sh || true
sudo rm -rf /etc/rancher /var/lib/rancher

# 설치 실행
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_SKIP_SELINUX_RPM=true \
  K3S_URL=https://$MASTER_PUBLIC_IP:6443 \
  K3S_TOKEN=$K3S_TOKEN \
  sh -
