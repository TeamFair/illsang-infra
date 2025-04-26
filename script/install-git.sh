#!/bin/bash
set -ex

# 루트로 올라가기
sudo -i

# git 설치
yum install -y git

# 설치 완료 후 GitHub 클론
git clone https://github.com/TeamFair/illsang-infra.git