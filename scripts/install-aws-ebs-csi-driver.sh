#!/usr/bin/env bash

EKS_CLUSTER_NAME="eks-demo"

echo "[debug] detecting AWS Account ID"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "[debug] AWS Account ID: ${AWS_ACCOUNT_ID}"

echo "[debug] detecting chart repo [aws-ebs-csi-driver] existance"
helm repo list | grep -q 'aws-ebs-csi-driver'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo [aws-ebs-csi-driver]"
  helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver || true
else
  echo "[debug] found chart repo [aws-ebs-csi-driver]"
fi

echo "[debug] helm repo update"
helm repo update

echo "[debug] detecting IAM policy 'AmazonEKS_EBS_CSI_Driver_Policy' existance"
aws iam list-policies --query "Policies[].[PolicyName,UpdateDate]" --output text | grep 'AmazonEKS_EBS_CSI_Driver_Policy'

if [ $? -ne 0 ]; then
  echo "[debug] IAM policy 'AmazonEKS_EBS_CSI_Driver_Policy' existance not found, creating"
  curl -o aws-ebs-csi-driver-policy.json \
    https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v1.5.1/docs/example-iam-policy.json
  aws iam create-policy \
    --policy-name AmazonEKS_EBS_CSI_Driver_Policy \
    --policy-document file://aws-ebs-csi-driver-policy.json
else
  echo "[debug] found IAM policy 'AmazonEKS_EBS_CSI_Driver_Policy'"
fi

echo "[debug] ensure existance of IAM Service Account 'ebs-csi-controller-sa'"
eksctl create iamserviceaccount \
  --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} \
  --name ebs-csi-controller-sa \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AmazonEKS_EBS_CSI_Driver_Policy \
  --approve \
  --override-existing-serviceaccounts

echo "[debug] detecting aws-ebs-csi-driver/aws-ebs-csi-driver existance"
helm -n kube-system ls | grep -q 'aws-ebs-csi-driver/aws-ebs-csi-driver'

if [ $? -ne 0 ]; then
  # TODO: nice to have regional image setup
  echo "[debug] setup aws-ebs-csi-driver/aws-ebs-csi-driver"
  helm upgrade \
    --namespace kube-system \
    --install aws-ebs-csi-driver \
    aws-ebs-csi-driver/aws-ebs-csi-driver \
      --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-ebs-csi-driver \
      --set controller.serviceAccount.create=false \
      --set controller.serviceAccount.name=ebs-csi-controller-sa
else
  echo "[debug] found aws-ebs-csi-driver/aws-ebs-csi-driver"
fi
