# eks-tutorials

Step by step tutorial for who have no experience to Amazon EKS. After finished the tutorial, you should be able to run general workload with Amazon EKS. Hope you enjoy the journey.

### Disclaimer

Please note this tutorial is for demonstration purpose only, please **_DO NOT_** blindly apply it to your production environments.

## Prerequisites

- [eksctl](https://eksctl.io/) - The official CLI for Amazon EKS
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - The Kubernetes command-line tool
- [helm](https://helm.sh/) - The Kubernetes Package Manage

### Assumptions

- Your AWS Profile have proper permission configured.
- All the tools required were setup properly
- All the resources are under `us-east-1`
- The cluster name would be `eks-demo`

## Guideline of the tutorial

- Goal 1: Create EKS Cluster with `eksctl`
- Goal 2: Deploy nginx with Application Load Balancer (ALB)
- Goal 3: Find out why Application Load Balancer (ALB) not working?
- Goal 4: Find out why Horizontal Pod Autoscaling (HPA) not working?
- Goal 5: HPA is working. Now I want to set Nginx replicas with `kubectl scale ...` but failed. Why?
- Goal 6: Remove HPA and try to scale to `20` manually
- Goal 7: Try to turn ALB entry from HTTP to HTTPS
- Goal 8: How to switch to Network Load Balancer (NLB)?
- Goal 9: Cleanup


### Goal 1: Create EKS Cluster with `eksctl`

Make sure you have latest `eksctl` installed and you should be able to create EKS cluster with minimal setup as follow.

```sh
% eksctl create cluster -f ./cluster-config/cluster-minimal.yaml
```

<details>
<summary>Click here to show sample deployment output :mag:</summary>

```
2023-XX-XX XX:XX:XX [ℹ]  eksctl version 0.138.0
2023-XX-XX XX:XX:XX [ℹ]  using region us-east-1
2023-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1a - public:192.168.0.0/19 private:192.168.64.0/19
2023-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1b - public:192.168.32.0/19 private:192.168.96.0/19
2023-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" will use "" [AmazonLinux2/1.26]
2023-XX-XX XX:XX:XX [ℹ]  using Kubernetes version 1.26
2023-XX-XX XX:XX:XX [ℹ]  creating EKS cluster "eks-demo" in "us-east-1" region with managed nodes
2023-XX-XX XX:XX:XX [ℹ]  1 nodegroup (mng-1) was included (based on the include/exclude rules)
2023-XX-XX XX:XX:XX [ℹ]  will create a CloudFormation stack for cluster itself and 0 nodegroup stack(s)
2023-XX-XX XX:XX:XX [ℹ]  will create a CloudFormation stack for cluster itself and 1 managed nodegroup stack(s)
2023-XX-XX XX:XX:XX [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-east-1 --cluster=eks-demo'
2023-XX-XX XX:XX:XX [ℹ]  Kubernetes API endpoint access will use default of {publicAccess=true, privateAccess=false} for cluster "eks-demo" in "us-east-1"
2023-XX-XX XX:XX:XX [ℹ]  configuring CloudWatch logging for cluster "eks-demo" in "us-east-1" (enabled types: api, audit, authenticator, controllerManager, scheduler & no types disabled)
2023-XX-XX XX:XX:XX [ℹ]
2 sequential tasks: { create cluster control plane "eks-demo",
    2 sequential sub-tasks: {
        5 sequential sub-tasks: {
            wait for control plane to become ready,
            update CloudWatch log retention,
            associate IAM OIDC provider,
            2 sequential sub-tasks: {
                create IAM role for serviceaccount "kube-system/aws-node",
                create serviceaccount "kube-system/aws-node",
            },
            restart daemonset "kube-system/aws-node",
        },
        create managed nodegroup "mng-1",
    }
}
2023-XX-XX XX:XX:XX [ℹ]  building cluster stack "eksctl-eks-demo-cluster"
2023-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-cluster"
2023-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2023-XX-XX XX:XX:XX [ℹ]  set log retention to 90 days for CloudWatch logging
2023-XX-XX XX:XX:XX [ℹ]  building iamserviceaccount stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2023-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2023-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2023-XX-XX XX:XX:XX [ℹ]  serviceaccount "kube-system/aws-node" already exists
2023-XX-XX XX:XX:XX [ℹ]  updated serviceaccount "kube-system/aws-node"
2023-XX-XX XX:XX:XX [ℹ]  daemonset "kube-system/aws-node" restarted
2023-XX-XX XX:XX:XX [ℹ]  building managed nodegroup stack "eksctl-eks-demo-nodegroup-mng-1"
2023-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-nodegroup-mng-1"
2023-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-nodegroup-mng-1"
2023-XX-XX XX:XX:XX [ℹ]  waiting for the control plane to become ready
2023-XX-XX XX:XX:XX [✔]  saved kubeconfig as "/Users/demoUser/.kube/config"
2023-XX-XX XX:XX:XX [ℹ]  no tasks
2023-XX-XX XX:XX:XX [✔]  all EKS cluster resources for "eks-demo" have been created
2023-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" has 2 node(s)
2023-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-75-113.ec2.internal" is ready
2023-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-99-9.ec2.internal" is ready
2023-XX-XX XX:XX:XX [ℹ]  waiting for at least 2 node(s) to become ready in "mng-1"
2023-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" has 2 node(s)
2023-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-75-113.ec2.internal" is ready
2023-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-99-9.ec2.internal" is ready
2023-XX-XX XX:XX:XX [ℹ]  kubectl command should work with "/Users/demoUser/.kube/config", try 'kubectl get nodes'
2023-XX-XX XX:XX:XX [✔]  EKS cluster "eks-demo" in "us-east-1" region is ready
```
</details>

Verify the EKS nodes are running.

```sh
% kubectl get nodes
NAME                             STATUS   ROLES    AGE     VERSION
ip-192-168-75-113.ec2.internal   Ready    <none>   4m18s   v1.24.9-eks-49d8fe8
ip-192-168-99-9.ec2.internal     Ready    <none>   4m34s   v1.24.9-eks-49d8fe8
```

### Goal 2: Deploy nginx with Application Load Balancer (ALB)

At this stage, you would need to have `kubectl` installed. Then you should be able to create `Deployment`, `HPA`, `Service` and `Ingress` resources.

```sh
% kubectl apply -f ./examples/simple/
deployment.apps/nginx-deployment created
horizontalpodautoscaler.autoscaling/nginx-hpa created
ingress.networking.k8s.io/nginx-ingress created
service/nginx-service created
```

Make sure everything run as expected

```sh
% kubectl get pods,deployments,hpa,service,ingress
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-69c78cd8c6-bnh44   1/1     Running   0          11s
pod/nginx-deployment-69c78cd8c6-n4l7p   1/1     Running   0          11s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   2/2     2            2           13s

NAME                                            REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/nginx-hpa   Deployment/nginx-deployment   <unknown>/80%   2         10        0          13s

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/kubernetes      ClusterIP   10.100.0.1       <none>        443/TCP        15m
service/nginx-service   NodePort    10.100.102.191   <none>        80:30753/TCP   11s

NAME                                      CLASS    HOSTS                ADDRESS   PORTS   AGE
ingress.networking.k8s.io/nginx-ingress   <none>   entry1.example.com             80      31s
```

### Goal 3: Find out why Application Load Balancer (ALB) not working?

```sh
% kubectl get ingress nginx-ingress
NAME            CLASS    HOSTS                ADDRESS   PORTS   AGE
nginx-ingress   <none>   entry1.example.com             80      81s # <-------- no address shown, why?
```

After fixing the issue, you should be able to see command output as follow,

```sh
% kubectl get ingress nginx-ingress
NAME            CLASS    HOSTS                ADDRESS                                     PORTS   AGE
nginx-ingress   <none>   entry1.example.com   k8s-XXXXXXXXX.us-east-1.elb.amazonaws.com   80      4m39s
```

Once the Load Balancer is created, you should be able to visit the application via the endpoint of load balancer with default `HTTP` protocol.

### Goal 4: Find out why Horizontal Pod Autoscaling (HPA) not working?

```sh
% kubectl get hpa nginx-hpa
NAME        REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   <unknown>/80%   2         10        2          29s
```

Did you aware that HPA is not working... why? :thinking:

After you fixed the HPA issue, it should shown as follow

```sh
% kubectl get hpa nginx-hpa
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   2%/80%    2         10        2          10m
```

### Goal 5: HPA is working. Now I want to set Nginx replicas with `kubectl scale ...` but failed. Why?

```sh
% kubectl scale --replicas 12 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
```

Why the Pod count not able to reach desired pod count `12` but quickly scale down back to `10`... why is that ?

### Goal 6: Remove HPA and try to scale to `20` manually

```sh
% kubectl delete hpa nginx-hpa
horizontalpodautoscaler.autoscaling "nginx-hpa" deleted
```

```sh
% kubectl get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   13/20   20           13          31m # <-------- stock at "13/20" ...why?
```

```sh
% kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-848df8ccf4-4q454   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-7j9l5   1/1     Running   0          15m
nginx-deployment-848df8ccf4-99tbb   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-9ndx9   0/1     Pending   0          8m3s # <-------- Pending
nginx-deployment-848df8ccf4-f82zc   0/1     Pending   0          8m3s # <-------- Pending
nginx-deployment-848df8ccf4-fbk2t   0/1     Pending   0          8m3s # <-------- Pending
nginx-deployment-848df8ccf4-gmqkd   1/1     Running   0          14m
nginx-deployment-848df8ccf4-gscdm   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-jlv7q   0/1     Pending   0          8m3s # <-------- Pending
nginx-deployment-848df8ccf4-jr9b9   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-jxbh9   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-rvpdn   0/1     Pending   0          8m3s # <-------- Pending
nginx-deployment-848df8ccf4-t2kj9   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-vgk4h   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-vn6v5   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-x6qrj   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-x6tb9   0/1     Pending   0          8m3s # <-------- Pending
nginx-deployment-848df8ccf4-xd4f8   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-xm5s9   1/1     Running   0          8m3s
nginx-deployment-848df8ccf4-zkg5z   0/1     Pending   0          8m3s # <-------- Pending
```

### Goal 7: Try to turn ALB entry from HTTP to HTTPS

Service with `HTTP` is clearly unsafe, how to made it safe with `HTTPS`?

### Goal 8: How to switch to Network Load Balancer (NLB)?

If you solve can provision ALB then you should be able to create NLB as well. But how...? :thinking:

### Goal 9: Cleanup

Terminate all resources that we created earlier.

```sh
% kubectl delete -f ./examples/simple/ --ignore-not-found
```

Terminate the EKS cluster

:warning: **_WARNING: all resources will be removed permanently, unrecoverable_**

```sh
% eksctl delete cluster -f ./cluster-config/cluster-minimal.yaml
```

**OPTIONAL** Cleanup IAM User/Role/Policy and [Identity Provider (IdP)](https://console.aws.amazon.com/iamv2/home?#/identity_providers) with care.

### Bonus

There's another repository with common used addons installation scripts:

- https://github.com/guessi/eks-addons-quick-start
