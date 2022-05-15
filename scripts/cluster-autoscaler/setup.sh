#!/usr/bin/env bash

AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="eks-demo"
POLICY_NAME="AmazonEKSClusterAutoscalerPolicy"
SERVICE_ACCOUNT_NAME="cluster-autoscaler"
CLUSTER_AUTOSCALER_IMAGE_TAG="v1.22.2"

echo "[debug] detecting AWS Account ID"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "[debug] AWS Account ID: ${AWS_ACCOUNT_ID}"

echo "[debug] detecting chart repo existance"
helm repo list | grep -q 'autoscaler'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo"
  helm repo add autoscaler https://kubernetes.github.io/autoscaler || true
else
  echo "[debug] found chart repo"
fi

echo "[debug] helm repo update"
helm repo update autoscaler

echo "[debug] detecting IAM policy existance"
aws iam list-policies --query "Policies[].[PolicyName,UpdateDate]" --output text | grep "${POLICY_NAME}"

if [ $? -ne 0 ]; then
  echo "[debug] IAM policy existance not found, creating"
  aws iam create-policy \
    --policy-name ${POLICY_NAME} \
    --policy-document file://policy.json
else
  echo "[debug] IAM policy existed"
fi

echo "[debug] creating IAM Roles for Service Accounts"
eksctl create iamserviceaccount \
  --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} \
  --name ${SERVICE_ACCOUNT_NAME} \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME} \
  --approve \
  --override-existing-serviceaccounts

echo "[debug] detecting Helm resource existance"
helm list --all-namespaces | grep -q 'cluster-autoscaler'

if [ $? -ne 0 ]; then
  echo "[debug] setup eks/cluster-autoscaler"
  helm upgrade \
    --namespace kube-system \
    --install cluster-autoscaler \
    autoscaler/cluster-autoscaler \
      --set rbac.serviceAccount.create=false \
      --set rbac.serviceAccount.name=${SERVICE_ACCOUNT_NAME} \
      --set autoDiscovery.clusterName=${EKS_CLUSTER_NAME} \
      --set fullnameOverride="cluster-autoscaler" \
      --set image.tag="${CLUSTER_AUTOSCALER_IMAGE_TAG}"
else
  echo "[debug] Helm resource existed"
fi
