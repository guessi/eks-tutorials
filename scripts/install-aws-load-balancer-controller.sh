#!/usr/bin/env bash

AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="eks-demo"

echo "[debug] detecting AWS Account ID"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "[debug] AWS Account ID: ${AWS_ACCOUNT_ID}"

echo "[debug] detecting VPC ID"
export VPC_ID=$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query 'cluster.resourcesVpcConfig.vpcId' --output text --region ${AWS_REGION})
echo "[debug] VPC ID: ${VPC_ID}"

echo "[debug] detecting chart repo [eks-charts] existance"
helm repo list | grep -q 'eks-charts'

if [ $? -ne 0 ]; then
  echo "[debug] setup chart repo [eks-charts]"
  helm repo add eks https://aws.github.io/eks-charts || true
else
  echo "[debug] found chart repo [eks-charts]"
fi

echo "[debug] helm repo update"
helm repo update

echo "[debug] detecting IAM policy 'AWSLoadBalancerControllerIAMPolicy' existance"
aws iam list-policies --query "Policies[].[PolicyName,UpdateDate]" --output text | grep 'AWSLoadBalancerControllerIAMPolicy'

if [ $? -ne 0 ]; then
  echo "[debug] IAM policy 'AWSLoadBalancerControllerIAMPolicy' existance not found, creating"
  curl -o aws-load-balancer-controller-policy.json \
    https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.0/docs/install/iam_policy.json
  aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://aws-load-balancer-controller-policy.json
else
  echo "[debug] found IAM policy 'AWSLoadBalancerControllerIAMPolicy'"
fi

echo "[debug] ensure existance of IAM Service Account 'aws-load-balancer-controller'"
eksctl create iamserviceaccount \
  --namespace kube-system \
  --cluster ${EKS_CLUSTER_NAME} \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

echo "[debug] detecting eks/aws-load-balancer-controller existance"
helm -n kube-system ls | grep -q 'aws-load-balancer-controller'

if [ $? -ne 0 ]; then
  # TODO: nice to have regional image setup
  echo "[debug] setup eks/aws-load-balancer-controller"
  helm upgrade \
    --namespace kube-system \
    --install aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
      --set clusterName=${EKS_CLUSTER_NAME} \
      --set serviceAccount.create=false \
      --set serviceAccount.name=aws-load-balancer-controller \
      --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller \
      --set region=${AWS_REGION} \
      --set VpcId=${VPC_ID}
else
  echo "[debug] found eks/aws-load-balancer-controller"
fi
