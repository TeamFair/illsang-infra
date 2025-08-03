#!/bin/bash
set -ex

# swap 생성 및 활성화
#fallocate -l 1G /swapfile
#chmod 600 /swapfile
#mkswap /swapfile
#swapon /swapfile
#echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 시간대 설정
timedatectl set-timezone Asia/Seoul

# K3s 설치 (Traefik, servicelb, metrics-server 비활성화)
export INSTALL_K3S_SKIP_SELINUX_RPM=true
curl -sfL https://get.k3s.io | sh -s - server \
  #--disable traefik \
  --disable servicelb \
  --write-kubeconfig-mode 644

# KUBECONFIG 환경변수 설정
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> /etc/profile.d/kubeconfig.sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Helm 설치
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Helm PATH 보장
echo 'export PATH=$PATH:/usr/local/bin' >> /etc/profile.d/helm-path.sh
export PATH=$PATH:/usr/local/bin