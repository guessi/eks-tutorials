#!/usr/bin/env bash

echo "[debug] detecting chart repo existance"
helm repo list | grep -q 'metrics-server'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo"
  helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server || true
else
  echo "[debug] found chart repo"
fi

echo "[debug] helm repo update"
helm repo update metrics-server

echo "[debug] detecting Helm resource existance"
helm list --all-namespaces | grep -q 'metrics-server'

if [ $? -ne 0 ]; then
  echo "[debug] setup metrics-server"
  helm upgrade \
    --namespace kube-system \
    --install metrics-server \
    metrics-server/metrics-server
else
  echo "[debug] Helm resource existed"
fi
