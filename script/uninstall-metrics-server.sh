#!/bin/bash
set -euxo pipefail
helm uninstall metrics-server -n kube-system || true
kubectl delete apiservice v1beta1.metrics.k8s.io --ignore-not-found
