#!/usr/bin/env bash

EKS_CLUSTER_NAME="eks-demo"

echo "[debug] detecting AWS Account ID"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "[debug] AWS Account ID: ${AWS_ACCOUNT_ID}"

echo "[debug] detecting chart repo [autoscaler] existance"
helm repo list | grep -q 'autoscaler'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo [autoscaler]"
  helm repo add autoscaler https://kubernetes.github.io/autoscaler || true
else
  echo "[debug] found chart repo [autoscaler]"
fi

echo "[debug] helm repo update"
helm repo update

echo "[debug] detecting IAM policy 'AmazonEKSClusterAutoscalerPolicy' existance"
aws iam list-policies --query "Policies[].[PolicyName,UpdateDate]" --output text | grep 'AmazonEKSClusterAutoscalerPolicy'

if [ $? -ne 0 ]; then
  echo "[debug] IAM policy 'AmazonEKSClusterAutoscalerPolicy' existance not found, creating"
  aws iam create-policy \
    --policy-name AmazonEKSClusterAutoscalerPolicy \
    --policy-document file://policy.json
else
  echo "[debug] found IAM policy 'AmazonEKSClusterAutoscalerPolicy'"
fi

echo "[debug] ensure existance of IAM Service Account 'cluster-autoscaler'"
eksctl create iamserviceaccount \
  --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} \
  --name cluster-autoscaler \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKSClusterAutoscalerPolicy \
  --override-existing-serviceaccounts \
  --approve

echo "[debug] detecting autoscaler/cluster-autoscaler existance"
helm -n kube-system ls | grep -q 'cluster-autoscaler'

if [ $? -ne 0 ]; then
  echo "[debug] setup eks/cluster-autoscaler"
  helm upgrade \
    --namespace kube-system \
    --install cluster-autoscaler \
    autoscaler/cluster-autoscaler \
      --set rbac.serviceAccount.create=false \
      --set rbac.serviceAccount.name=cluster-autoscaler \
      --set "autoDiscovery.clusterName=${EKS_CLUSTER_NAME}"
else
  echo "[debug] found autoscaler/cluster-autoscaler"
fi
