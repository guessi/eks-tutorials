# eks-tutorials

step-by-step tutorial for creating services on EKS cluster with eksctl

### Disclaimer

Please note this tutorial is for demonstration purpose only, please **_DO NOT_** blindly apply it to your production environments.

## Prerequisites

- [Amazon EKS](https://aws.amazon.com/eks/) 1.19+
- [eksctl](https://eksctl.io/) - The official CLI for Amazon EKS
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - The Kubernetes command-line tool
- [helm](https://helm.sh/) - The Kubernetes Package Manage

### Assumptions

- An AWS profile existed with name `default`, and `AdministratorAccess` permission configured
- All the tools required were setup properly
- All the resources are under `us-east-1`
- The cluster name would be `eks-demo`

### Tools version used in this tutorial

```sh
% eksctl version
0.84.0

% kubectl version --client --short
Client Version: v1.23.4

% helm version --short
v3.8.0+gd141386
```

## Goals

- Goal 1: Create EKS Cluster
- Goal 2: Deploy a simple application with Classic Load Balancer (CLB) on EKS cluster
- Goal 3: Find out why some pods not being scheduled?
- Goal 4: Access web application via Load Balancer
- Goal 5: Try to provision application with Application Load Balancer (ALB)
- Goal 6: Try to provision application with Network Load Balancer (NLB)
- Goal 7: Horizontal Pod Autoscaling (HPA) not working
- Goal 8: Cleanup


### Goal 1: Create EKS Cluster

Create EKS cluster with minimal setup (for demo purpose only)

```sh
% eksctl create cluster -f ./cluster-config/cluster-minimal.yaml
```

<details>
<summary>Click here to show sample deployment output :mag:</summary>

```
2022-XX-XX XX:XX:XX [ℹ]  eksctl version 0.84.0
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
2022-XX-XX XX:XX:XX [ℹ]  configuring CloudWatch logging for cluster "eks-demo" in "us-east-1" (enabled types: audit & disabled types: api, authenticator, controllerManager, scheduler)
2022-XX-XX XX:XX:XX [ℹ]
2 sequential tasks: { create cluster control plane "eks-demo",
    2 sequential sub-tasks: {
        5 sequential sub-tasks: {
            wait for control plane to become ready,
            associate IAM OIDC provider,
            no tasks,
            restart daemonset "kube-system/aws-node",
            1 task: { create addons },
        },
        create managed nodegroup "managed-1",
    }
}
2022-XX-XX XX:XX:XX [ℹ]  building cluster stack "eksctl-eks-demo-cluster"
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-cluster"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2022-XX-XX XX:XX:XX [ℹ]  daemonset "kube-system/aws-node" restarted
2022-XX-XX XX:XX:XX [ℹ]  creating role using recommended policies
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-addon-vpc-cni"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-addon-vpc-cni"
2022-XX-XX XX:XX:XX [ℹ]  creating addon
2022-XX-XX XX:XX:XX [ℹ]  successfully created addon
2022-XX-XX XX:XX:XX [ℹ]  building managed nodegroup stack "eksctl-eks-demo-nodegroup-managed-1"
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-nodegroup-managed-1"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-nodegroup-managed-1"
2022-XX-XX XX:XX:XX [ℹ]  waiting for the control plane availability...
2022-XX-XX XX:XX:XX [✔]  saved kubeconfig as "/Users/demoUser/.kube/config"
2022-XX-XX XX:XX:XX [ℹ]  no tasks
2022-XX-XX XX:XX:XX [✔]  all EKS cluster resources for "eks-demo" have been created
2022-XX-XX XX:XX:XX [ℹ]  nodegroup "managed-1" has 2 node(s)
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-23-115.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-37-100.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  waiting for at least 2 node(s) to become ready in "managed-1"
2022-XX-XX XX:XX:XX [ℹ]  nodegroup "managed-1" has 2 node(s)
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-23-115.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-37-100.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  no recommended policies found, proceeding without any IAM
2022-XX-XX XX:XX:XX [ℹ]  creating addon
2022-XX-XX XX:XX:XX [ℹ]  addon "coredns" active
2022-XX-XX XX:XX:XX [ℹ]  no recommended policies found, proceeding without any IAM
2022-XX-XX XX:XX:XX [ℹ]  creating addon
2022-XX-XX XX:XX:XX [ℹ]  addon "kube-proxy" active

# Don't report this issue, it's an known issue for eksctl 0.84.0, and will be solved after 0.86.0 release, ref: https://github.com/weaveworks/eksctl/pull/4834

2022-XX-XX XX:XX:XX [✖]  unable to use kubectl with the EKS cluster (check 'kubectl version'): Unable to connect to the server: getting credentials: exec plugin is configured to use API version client.authentication.k8s.io/v1alpha1, plugin returned version client.authentication.k8s.io/v1beta1

2022-XX-XX XX:XX:XX [✔]  EKS cluster "eks-demo" in "us-east-1" region is ready
```
</details>

Get EKS cluster nodes information

```sh
% kubectl get nodes
NAME                             STATUS   ROLES    AGE   VERSION
ip-192-168-23-115.ec2.internal   Ready    <none>   35m   v1.21.5-eks-9017834
ip-192-168-37-100.ec2.internal   Ready    <none>   34m   v1.21.5-eks-9017834
```

### Goal 2: Deploy a simple application with Classic Load Balancer (CLB) on EKS cluster

Create `Deployment` and `Service` with predefined yaml configs, let's try `nginx-full-clb.yaml` first.

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
nginx-deployment-848df8ccf4-jsj8q   1/1     Running   0          74s
nginx-deployment-848df8ccf4-kzz7z   1/1     Running   0          74s
nginx-deployment-848df8ccf4-mq9c6   1/1     Running   0          74s
nginx-deployment-848df8ccf4-pwcd6   1/1     Running   0          74s
```

At this step, if you create cluster with `cluster-full.yaml`, you might sometimes find some pods stock in `Pending` state, why? :thinking:

### Goal 3: Find out why some pods not being scheduled?

Please try to find the reason by yourself.

### Goal 4: Access web application via Load Balancer

```sh
% kubectl get service nginx-service
NAME            TYPE           CLUSTER-IP       EXTERNAL-IP                             PORT(S)        AGE
nginx-service   LoadBalancer   10.100.153.172   xxxx-xxxx.us-east-1.elb.amazonaws.com   80:32580/TCP   110s
```

Once the Load Balancer is created, you should be able to visit the application via the endpoint of load balancer with `HTTP` scheme.

### Goal 5: Try to provision application with Application Load Balancer (ALB)

Please try to apply `nginx-full-alb.yaml` and find out why it's not working... :thinking:

### Goal 6: Try to provision application with Network Load Balancer (NLB)

If you solve can provision ALB then you should be able to create NLB by applying `nginx-full-nlb.yaml` as well.

### Goal 7: Horizontal Pod Autoscaling (HPA) not working

If you try to increase work load to pods and you will find out that HPA is not working... why? :thinking:

### Goal 8: Cleanup

Terminate all applications created earlier

```sh
% kubectl delete -f ./examples/nginx-full-nlb.yaml --ignore-not-found
% kubectl delete -f ./examples/nginx-full-alb.yaml --ignore-not-found
% kubectl delete -f ./examples/nginx-full-clb.yaml --ignore-not-found
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

<details>
<summary>Click here for bonus :mag:</summary>

You may find some useful installation scripts for install addons to your cluster under "./scripts" folder

#### Supported Addons:

- AWS EBS CSI Driver
- AWS EFS CSI Driver
- AWS Load Balancer Controller
- Cluster AutoScaler
- Metrics Server
</details>
