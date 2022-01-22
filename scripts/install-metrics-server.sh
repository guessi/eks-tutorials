#!/usr/bin/env bash

helm upgrade \
  --namespace kube-system \
  --install metrics-server \
  metrics-server/metrics-server
