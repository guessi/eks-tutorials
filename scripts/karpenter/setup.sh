#!/usr/bin/env bash

AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="eks-demo"
POLICY_NAME="KarpenterControllerPolicy-${EKS_CLUSTER_NAME}"
SERVICE_ACCOUNT_NAME="karpenter"
ROLE_NAME="${EKS_CLUSTER_NAME}-karpenter"

# CHART VERSION	APP VERSION
# ---------------------------
# 0.11.1        	0.11.1
# 0.11.0        	0.11.0
# 0.10.1        	0.10.1

APP_VERSION="0.11.1"
CHART_VERSION="0.11.1"

echo "[debug] detecting AWS Account ID"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "[debug] AWS Account ID: ${AWS_ACCOUNT_ID}"

echo "[debug] detecting cluster endpoint"
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query "cluster.endpoint" --output text --region ${AWS_REGION})"
echo "[debug] CLUSTER ENDPOINT: ${CLUSTER_ENDPOINT}"

echo "[debug] detecting namespace existance"
kubectl get namespace | grep -q 'karpenter'
if [ $? -ne 0 ]; then
  kubectl create namespace karpenter
else
  echo "[debug] namespace existed"
fi

echo "[debug] detecting chart repo existance"
helm repo list | grep -q 'karpenter'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo"
  helm repo add karpenter https://charts.karpenter.sh/ || true
else
  echo "[debug] found chart repo"
fi

echo "[debug] helm repo update"
helm repo update karpenter

echo "[debug] setup IAM resources"
curl -fsSL "https://karpenter.sh/v${APP_VERSION}/getting-started/getting-started-with-eksctl/cloudformation.yaml" -O

aws cloudformation deploy \
  --stack-name "Karpenter-${EKS_CLUSTER_NAME}" \
  --template-file cloudformation.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${EKS_CLUSTER_NAME}"

rm -vf cloudformation.yaml # cleanup

echo "[debug] creating mapRole for aws-auth"
eksctl create iamidentitymapping \
  --username "system:node:{{EC2PrivateDNSName}}" \
  --cluster "${EKS_CLUSTER_NAME}" \
  --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${EKS_CLUSTER_NAME}" \
  --group "system:bootstrappers" \
  --group "system:nodes"

echo "[debug] creating IAM Roles for Service Accounts"
eksctl create iamserviceaccount \
  --namespace karpenter \
  --cluster ${EKS_CLUSTER_NAME} \
  --name ${SERVICE_ACCOUNT_NAME} \
  --role-name "${ROLE_NAME}" \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME} \
  --approve \
  --override-existing-serviceaccounts

echo "[debug] detecting Helm resource existance"
helm list --all-namespaces | grep -q 'karpenter'

if [ $? -ne 0 ]; then
  echo "[debug] setup karpenter/karpenter"
  helm upgrade \
    --namespace karpenter \
    --install karpenter \
    --version ${CHART_VERSION} \
    karpenter/karpenter \
      --set serviceAccount.create=false \
      --set serviceAccount.name=${SERVICE_ACCOUNT_NAME} \
      --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}" \
      --set clusterName=${EKS_CLUSTER_NAME} \
      --set clusterEndpoint=${CLUSTER_ENDPOINT} \
      --set aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${EKS_CLUSTER_NAME} \
      --wait # for the defaulting webhook to install before creating a Provisioner
else
  echo "[debug] Helm resource existed"
fi

echo "[debug] listing installed"
helm list --all-namespaces --filter karpenter
