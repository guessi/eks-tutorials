#!/usr/bin/env bash

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

helm upgrade \
  --namespace kube-system \
  --install metrics-server \
  metrics-server/metrics-server
