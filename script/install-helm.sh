#!/bin/bash
set -euxo pipefail

# curl 필요 시 설치(Amazon Linux 2/Ubuntu 호환)
if ! command -v curl >/dev/null 2>&1; then
  (yum install -y curl) || (apt-get update && apt-get install -y curl)
fi

# Helm 설치(이미 있으면 스킵)
if ! command -v helm >/dev/null 2>&1 && [ ! -x /usr/local/bin/helm ]; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# PATH 보장(현재 쉘 + 로그인/sudo)
echo 'export PATH=$PATH:/usr/local/bin' | tee /etc/profile.d/helm-path.sh >/dev/null
export PATH=$PATH:/usr/local/bin
# sudo secure_path도 갱신(선택)
if [ ! -f /etc/sudoers.d/secure_path ]; then
  echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' > /etc/sudoers.d/secure_path
  visudo -cf /etc/sudoers.d/secure_path
fi

helm version
