#!/usr/bin/env bash

# CHART VERSION	APP VERSION
# v1.8.0       	v1.8.0
# v1.7.2       	v1.7.2
# v1.7.1       	v1.7.1
# v1.7.0       	v1.7.0
# v1.6.3       	v1.6.3
# v1.6.2       	v1.6.2
# v1.6.1       	v1.6.1
# v1.6.0       	v1.6.0
# v1.5.5       	v1.5.5
# v1.5.4       	v1.5.4
# v1.5.3       	v1.5.3
# v1.5.2       	v1.5.2
# v1.5.1       	v1.5.1
# v1.5.0       	v1.5.0

# Pin version to 1.5.x to avoid api break
# - https://cert-manager.io/docs/release-notes/release-notes-1.6#v160
CHART_VERSION="v1.5.5"

echo "[debug] detecting chart repo existance"
helm repo list | grep -q 'cert-manager'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo"
  helm repo add jetstack https://charts.jetstack.io || true
else
  echo "[debug] found chart repo"
fi

echo "[debug] helm repo update"
helm repo update jetstack

echo "[debug] detecting Helm resource existance"
helm list --all-namespaces | grep -q 'cert-manager'

if [ $? -ne 0 ]; then
  echo "[debug] setup cert-manager"
  helm upgrade \
    --namespace cert-manager \
    --install cert-manager \
    jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --version ${CHART_VERSION} \
      --set installCRDs=true
else
  echo "[debug] Helm resource existed"
fi

echo "[debug] listing installed"
helm list --all-namespaces --filter cert-manager
