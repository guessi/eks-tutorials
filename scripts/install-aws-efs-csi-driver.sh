#!/usr/bin/env bash

AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="eks-demo"

echo "[debug] detecting AWS Account ID"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "[debug] AWS Account ID: ${AWS_ACCOUNT_ID}"

echo "[debug] detecting chart repo [aws-efs-csi-driver] existance"
helm repo list | grep -q 'aws-efs-csi-driver'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo [aws-efs-csi-driver]"
  helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver || true
else
  echo "[debug] found chart repo [aws-efs-csi-driver]"
fi

echo "[debug] helm repo update"
helm repo update

echo "[debug] detecting IAM policy 'AmazonEKS_EFS_CSI_Driver_Policy' existance"
aws iam list-policies --query "Policies[].[PolicyName,UpdateDate]" --output text | grep 'AmazonEKS_EFS_CSI_Driver_Policy'

if [ $? -ne 0 ]; then
  echo "[debug] IAM policy 'AmazonEKS_EFS_CSI_Driver_Policy' existance not found, creating"
  curl -o aws-efs-csi-driver-policy.json \
    https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.3.6/docs/iam-policy-example.json
  aws iam create-policy \
    --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
    --policy-document file://aws-efs-csi-driver-policy.json
else
  echo "[debug] found IAM policy 'AmazonEKS_EFS_CSI_Driver_Policy'"
fi

echo "[debug] ensure existance of IAM Service Account 'cluster-autoscaler'"
eksctl create iamserviceaccount \
  --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} \
  --name efs-csi-controller-sa \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EFS_CSI_Driver_Policy \
  --approve \
  --override-existing-serviceaccounts \
  --region ${AWS_REGION}

echo "[debug] detecting aws-efs-csi-driver/aws-efs-csi-driver existance"
helm -n kube-system ls | grep -q 'aws-efs-csi-driver/aws-efs-csi-driver'

if [ $? -ne 0 ]; then
  # TODO: nice to have regional image setup
  echo "[debug] setup eks/cluster-autoscaler"
  helm upgrade \
    --namespace kube-system \
    --install aws-efs-csi-driver \
    aws-efs-csi-driver/aws-efs-csi-driver \
    --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa
else
  echo "[debug] found aws-efs-csi-driver/aws-efs-csi-driver"
fi
