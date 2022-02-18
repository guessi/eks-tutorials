# eks-tutorials

step-by-step tutorial for creating services on EKS cluster with eksctl

## Prerequisite

- AWS Profile with permission "AdministratorAccess"
- eksctl - The official CLI for Amazon EKS
- kubectl - The Kubernetes command-line tool
- helm - The Kubernetes Package Manage

### Assumptions (**For demonstration purpose only**)

- An AWS profile existed with name "default", and "AdministratorAccess" permission configured
- All the tools required were setup properly
- All the resources are under "us-east-1"
- The cluster name would be "eks-demo"

<details>
<summary>Click here to see how to check tools version used in this tutorial :mag:</summary>

Check `eksctl` version

```sh
% eksctl version

0.82.0
```

Check `kubectl` version

```sh
% kubectl version --client --short

Client Version: v1.23.4
```

Check `helm` version

```sh
% helm version --short

v3.8.0+gd141386
```
</details>

## Goals

- Goal 1: Create EKS cluster
- Goal 2: Deploy a simple application on EKS cluster
- Goal 3: Find out why some pods not being scheduled
- Goal 4: Access web application via Load Balancer
- Goal 5: Find out why Load Balancer not working with `nginx-full-alb.yaml`
- Goal 6: Cleanup


### Goal 1: Create EKS Cluster

Create EKS cluster with minimal setup (for demo purpose only)

```sh
% eksctl create cluster -f ./cluster-config/cluster-minimal.yaml

# Start

2022-XX-XX XX:XX:XX [ℹ]  eksctl version 0.82.0
2022-XX-XX XX:XX:XX [ℹ]  using region us-east-1
2022-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1a - public:192.168.0.0/19 private:192.168.64.0/19
2022-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1b - public:192.168.32.0/19 private:192.168.96.0/19
2022-XX-XX XX:XX:XX [ℹ]  nodegroup "managed-1" will use "" [AmazonLinux2/1.21]
2022-XX-XX XX:XX:XX [ℹ]  using Kubernetes version 1.21
2022-XX-XX XX:XX:XX [ℹ]  creating EKS cluster "eks-demo" in "us-east-1" region with managed nodes
2022-XX-XX XX:XX:XX [ℹ]  1 nodegroup (managed-1) was included (based on the include/exclude rules)
2022-XX-XX XX:XX:XX [ℹ]  will create a CloudFormation stack for cluster itself and 0 nodegroup stack(s)
2022-XX-XX XX:XX:XX [ℹ]  will create a CloudFormation stack for cluster itself and 1 managed nodegroup stack(s)
2022-XX-XX XX:XX:XX [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-east-1 --cluster=eks-demo'
2022-XX-XX XX:XX:XX [ℹ]  Kubernetes API endpoint access will use default of {publicAccess=true, privateAccess=false} for cluster "eks-demo" in "us-east-1"
2022-XX-XX XX:XX:XX [ℹ]  CloudWatch logging will not be enabled for cluster "eks-demo" in "us-east-1"
2022-XX-XX XX:XX:XX [ℹ]  you can enable it with 'eksctl utils update-cluster-logging --enable-types={SPECIFY-YOUR-LOG-TYPES-HERE (e.g. all)} --region=us-east-1 --cluster=eks-demo'
2022-XX-XX XX:XX:XX [ℹ]
2 sequential tasks: { create cluster control plane "eks-demo",
    2 sequential sub-tasks: {
        4 sequential sub-tasks: {
            wait for control plane to become ready,
            associate IAM OIDC provider,
            2 sequential sub-tasks: {
                create IAM role for serviceaccount "kube-system/aws-node",
                create serviceaccount "kube-system/aws-node",
            },
            restart daemonset "kube-system/aws-node",
        },
        create managed nodegroup "managed-1",
    }
}

# Creating EKS Cluster

2022-XX-XX XX:XX:XX [ℹ]  building cluster stack "eksctl-eks-demo-cluster"
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-cluster"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"

# Creating IAM

2022-XX-XX XX:XX:XX [ℹ]  building iamserviceaccount stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2022-XX-XX XX:XX:XX [ℹ]  serviceaccount "kube-system/aws-node" already exists
2022-XX-XX XX:XX:XX [ℹ]  updated serviceaccount "kube-system/aws-node"
2022-XX-XX XX:XX:XX [ℹ]  daemonset "kube-system/aws-node" restarted

# Creating Managed Node Group

2022-XX-XX XX:XX:XX [ℹ]  building managed nodegroup stack "eksctl-eks-demo-nodegroup-managed-1"
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-nodegroup-managed-1"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-nodegroup-managed-1"
2022-XX-XX XX:XX:XX [ℹ]  waiting for the control plane availability...

# Configuring config for kubectl and wait for node ready

2022-XX-XX XX:XX:XX [✔]  saved kubeconfig as "/Users/demoUser/.kube/config"
2022-XX-XX XX:XX:XX [ℹ]  no tasks
2022-XX-XX XX:XX:XX [✔]  all EKS cluster resources for "eks-demo" have been created
2022-XX-XX XX:XX:XX [ℹ]  nodegroup "managed-1" has 2 node(s)
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-25-108.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-50-93.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  waiting for at least 2 node(s) to become ready in "managed-1"
2022-XX-XX XX:XX:XX [ℹ]  nodegroup "managed-1" has 2 node(s)
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-25-108.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-50-93.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  kubectl command should work with "/Users/demoUser/.kube/config", try 'kubectl get nodes'

# All done !!!

2022-XX-XX XX:XX:XX [✔]  EKS cluster "eks-demo" in "us-east-1" region is ready
```
</details>

Get EKS cluster nodes information

```sh
% kubectl get nodes
NAME                             STATUS   ROLES    AGE    VERSION
ip-192-168-25-108.ec2.internal   Ready    <none>   111m   v1.21.5-eks-9017834
ip-192-168-50-93.ec2.internal    Ready    <none>   111m   v1.21.5-eks-9017834
```


### Goal 2: Deploy a simple application on EKS cluster

Create `Deployment` and `Service` with predefined yaml configs, you may apply `nginx-full-clb.yaml` or `nginx-full-alb.yaml`.

```sh
% kubectl apply -f ./examples/nginx-full-clb.yaml

deployment.apps/nginx-deployment created
horizontalpodautoscaler.autoscaling/nginx-hpa created
service/nginx-service created
```

Wait until all the pods become "Running" state.

```sh
% kubectl get pods

NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6f4879f75d-5jdkk   1/1     Running   0          16s
nginx-deployment-6f4879f75d-hk47g   1/1     Running   0          16s
nginx-deployment-6f4879f75d-jv2jl   1/1     Running   0          16s
nginx-deployment-6f4879f75d-kqwtq   1/1     Running   0          16s
```

At this step, if you create cluster with `cluster-full.yaml`, you might find some pods stock in `Pending` state, why? :thinking:

### Goal 3: Find out why some pods not being scheduled?

Please try to find the reason by yourself.

### Goal 4: Access web application via Load Balancer

Get Load Balancer access url

```sh
% kubectl get service nginx-service
NAME            TYPE           CLUSTER-IP     EXTERNAL-IP                             PORT(S)        AGE
nginx-service   LoadBalancer   10.100.81.16   xxxx-xxxx.us-east-1.elb.amazonaws.com   80:31513/TCP   3m30s
```

Visit Load Balancer that created by Service (NOTE: with `HTTP` protocol, not `HTTPS`)

At this step, think of the following questions.

- What's the difference between `nginx-full-clb.yaml` and `nginx-full-alb.yaml`?
- Why is service stack created with `nginx-full-alb.yaml` not working? :thinking:

### Goal 5: Find out why Load Balancer not working with `nginx-full-alb.yaml`?

<details>
<summary>Click here to see the answer :mag:</summary>
Answer: Lack of AWS Load Balancer Controller support.

To setup AWS Load Balancer Controller, please follow the steps below to finish setup,

1) curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy.json

2) aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

3) export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

4) eksctl create iamserviceaccount \
     --cluster=eks-demo \
     --namespace=kube-system \
     --name=aws-load-balancer-controller \
     --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
     --override-existing-serviceaccounts \
     --approve

5) helm repo add eks https://aws.github.io/eks-charts

6) helm repo update

7) export VPC_ID=$(aws eks describe-cluster --name eks-demo --query 'cluster.resourcesVpcConfig.vpcId' --output text --region us-east-1)

8) helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=eks-demo \
     --set serviceAccount.create=false \
     --set serviceAccount.name=aws-load-balancer-controller \
     --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller \
     --set region=us-east-1 \
     --set VpcId=${VPC_ID}

After finish all the steps above, you should now have AWS Load Balancer Controller support.
</details>


### Goal 6: Cleanup

Terminate all applications created earlier

```sh
% kubectl delete -f ./examples/nginx-full-clb.yaml

deployment.apps "nginx-deployment" deleted
horizontalpodautoscaler.autoscaling "nginx-hpa" deleted
service "nginx-service" deleted
```

Terminate the EKS cluster

:warning: **_WARNING: all resources will be removed permanently, unrecoverable_**

```sh
% eksctl delete cluster -f ./cluster-config/cluster-minimal.yaml
```

Lastly, it's an **OPTIONAL** change, cleanup IAM policy

:warning: **_WARNING: you may want to keep it for other EKS clusters_**

```sh
% aws iam list-policies --output json | \
    jq -r '.Policies[] | select(.PolicyName | contains("AWSLoadBalancerControllerIAMPolicy")) | .Arn' | \
    xargs -n 1 aws iam delete-policy --policy-arn
```

and don't forget to cleanup Identity Provider (IdP) with care.
- https://console.aws.amazon.com/iamv2/home?#/identity_providers

### Bonus

You may find sample installation scripts for install addons to your cluster under "./scripts" folder

#### Supported Addons:

- AWS EBS CSI Driver
- AWS EFS CSI Driver
- AWS Load Balancer Controller
- Cluster AutoScaler
- Metrics Server

Please note it's for demonstration purpose only, please **_DO NOT_** blindly apply it to your production environments
