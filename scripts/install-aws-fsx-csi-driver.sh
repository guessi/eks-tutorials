#!/usr/bin/env bash

AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="eks-demo"

echo "[debug] detecting AWS Account ID"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "[debug] AWS Account ID: ${AWS_ACCOUNT_ID}"

echo "[debug] detecting chart repo [aws-fsx-csi-driver] existance"
helm repo list | grep -q 'aws-fsx-csi-driver'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo [aws-fsx-csi-driver]"
  helm repo add aws-fsx-csi-driver https://kubernetes-sigs.github.io/aws-fsx-csi-driver || true
else
  echo "[debug] found chart repo [aws-fsx-csi-driver]"
fi

echo "[debug] helm repo update"
helm repo update

echo "[debug] detecting IAM policy 'Amazon_FSx_Lustre_CSI_Driver' existance"
aws iam list-policies --query "Policies[].[PolicyName,UpdateDate]" --output text | grep 'Amazon_FSx_Lustre_CSI_Driver'

if [ $? -ne 0 ]; then
  echo "[debug] IAM policy 'Amazon_FSx_Lustre_CSI_Driver' existance not found, creating"
  aws iam create-policy \
    --policy-name Amazon_FSx_Lustre_CSI_Driver \
    --policy-document file://aws-fsx-csi-driver-policy.json
else
  echo "[debug] found IAM policy 'Amazon_FSx_Lustre_CSI_Driver'"
fi

echo "[debug] ensure existance of IAM Service Account 'fsx-csi-controller-sa'"
eksctl create iamserviceaccount \
  --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} \
  --name fsx-csi-controller-sa \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Amazon_FSx_Lustre_CSI_Driver \
  --approve \
  --override-existing-serviceaccounts \
  --region ${AWS_REGION}

echo "[debug] detecting aws-fsx-csi-driver/aws-fsx-csi-driver existance"
helm -n kube-system ls | grep -q 'aws-fsx-csi-driver/aws-fsx-csi-driver'

if [ $? -ne 0 ]; then
  echo "[debug] setup aws-fsx-csi-driver/aws-fsx-csi-driver"
  helm upgrade \
    --namespace kube-system \
    --install aws-fsx-csi-driver \
    aws-fsx-csi-driver/aws-fsx-csi-driver
else
  echo "[debug] found aws-fsx-csi-driver/aws-fsx-csi-driver"
fi
