# eks-tutorials

Step by step tutorial for who have no experience to Amazon EKS. After finished the tutorial, you should be able to run general workload with Amazon EKS. Hope you enjoy the journey.

### Disclaimer

Please note this tutorial is for demonstration purpose only, please **_DO NOT_** blindly apply it to your production environments.

## Prerequisites

- [eksctl](https://eksctl.io/) - The official CLI for Amazon EKS
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - The Kubernetes command-line tool
- [helm](https://helm.sh/) - The Kubernetes Package Manage
- [Amazon EKS 1.23](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions-extended.html#kubernetes-1.23) or higher - To support `autoscaling/v2`, learn more at [KEP-2702](https://github.com/kubernetes/enhancements/tree/master/keps/sig-autoscaling/2702-graduate-hpa-api-to-GA).

### `eksctl` version requirements

<details>
<summary>Click here :mag:</summary>

- To get support for Amazon EKS 1.28
    - support have been added after [eksctl-0.160.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.160.0) released.

- To get support for Amazon EKS 1.27
    - support have been added after [eksctl-0.143.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.143.0) released.

- To get support for Amazon EKS 1.26
    - support have been added after [eksctl-0.138.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.138.0) released.

- To get support for Amazon EKS 1.25
    - support have been added after [eksctl-0.132.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.132.0) released.

- To get support for Amazon EKS 1.24
    - support have been added after [eksctl-0.120.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.120.0) released.

- To get support for Amazon EKS 1.23
    - support have been added after [eksctl-0.109.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.109.0) released.

- To get support for Amazon EKS 1.22
    - support have been added after [eksctl-0.92.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.92.0) released.
    - support have been removed after [eksctl-0.151.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.151.0) released.

</details>

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
2023-XX-XX XX:XX:XX [ℹ]  eksctl version 0.162.0-rc.0
2023-XX-XX XX:XX:XX [ℹ]  using region us-east-1
2023-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1a - public:192.168.0.0/19 private:192.168.64.0/19
2023-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1b - public:192.168.32.0/19 private:192.168.96.0/19
2023-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" will use "" [AmazonLinux2/1.28]
2023-XX-XX XX:XX:XX [ℹ]  using Kubernetes version 1.28
2023-XX-XX XX:XX:XX [ℹ]  creating EKS cluster "eks-demo" in "us-east-1" region with managed nodes
2023-XX-XX XX:XX:XX [ℹ]  1 nodegroup (mng-1) was included (based on the include/exclude rules)
2023-XX-XX XX:XX:XX [ℹ]  will create a CloudFormation stack for cluster itself and 0 nodegroup stack(s)
2023-XX-XX XX:XX:XX [ℹ]  will create a CloudFormation stack for cluster itself and 1 managed nodegroup stack(s)
2023-XX-XX XX:XX:XX [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-east-1 --cluster=eks-demo'
2023-XX-XX XX:XX:XX [ℹ]  Kubernetes API endpoint access will use provided values {publicAccess=true, privateAccess=true} for cluster "eks-demo" in "us-east-1"
2023-XX-XX XX:XX:XX [ℹ]  configuring CloudWatch logging for cluster "eks-demo" in "us-east-1" (enabled types: api, audit, authenticator, controllerManager, scheduler & no types disabled)
2023-XX-XX XX:XX:XX [ℹ]
2 sequential tasks: { create cluster control plane "eks-demo",
    2 sequential sub-tasks: {
        6 sequential sub-tasks: {
            wait for control plane to become ready,
            update CloudWatch log retention,
            associate IAM OIDC provider,
            no tasks,
            restart daemonset "kube-system/aws-node",
            1 task: { create addons },
        },
        create managed nodegroup "mng-1",
    }
}
2023-XX-XX XX:XX:XX [ℹ]  building cluster stack "eksctl-eks-demo-cluster"
2023-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-cluster"
2023-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2023-XX-XX XX:XX:XX [ℹ]  set log retention to 90 days for CloudWatch logging
2023-XX-XX XX:XX:XX [ℹ]  daemonset "kube-system/aws-node" restarted
2023-XX-XX XX:XX:XX [ℹ]  creating role using recommended policies
2023-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-addon-vpc-cni"
2023-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-addon-vpc-cni"
2023-XX-XX XX:XX:XX [ℹ]  creating addon
2023-XX-XX XX:XX:XX [ℹ]  addon "vpc-cni" active
2023-XX-XX XX:XX:XX [ℹ]  building managed nodegroup stack "eksctl-eks-demo-nodegroup-mng-1"
2023-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-nodegroup-mng-1"
2023-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-nodegroup-mng-1"
2023-XX-XX XX:XX:XX [ℹ]  waiting for the control plane to become ready
2023-XX-XX XX:XX:XX [✔]  saved kubeconfig as "/Users/demoUser/.kube/config"
2023-XX-XX XX:XX:XX [ℹ]  no tasks
2023-XX-XX XX:XX:XX [✔]  all EKS cluster resources for "eks-demo" have been created
2023-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" has 2 node(s)
2023-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-104-74.ec2.internal" is ready
2023-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-71-34.ec2.internal" is ready
2023-XX-XX XX:XX:XX [ℹ]  waiting for at least 2 node(s) to become ready in "mng-1"
2023-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" has 2 node(s)
2023-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-104-74.ec2.internal" is ready
2023-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-71-34.ec2.internal" is ready
2023-XX-XX XX:XX:XX [ℹ]  no recommended policies found, proceeding without any IAM
2023-XX-XX XX:XX:XX [ℹ]  creating addon
2023-XX-XX XX:XX:XX [ℹ]  addon "coredns" active
2023-XX-XX XX:XX:XX [ℹ]  no recommended policies found, proceeding without any IAM
2023-XX-XX XX:XX:XX [ℹ]  creating addon
2023-XX-XX XX:XX:XX [ℹ]  addon "kube-proxy" active
2023-XX-XX XX:XX:XX [ℹ]  kubectl command should work with "/Users/demoUser/.kube/config", try 'kubectl get nodes'
2023-XX-XX XX:XX:XX [✔]  EKS cluster "eks-demo" in "us-east-1" region is ready
```
</details>

Verify the EKS nodes are running.

```sh
% kubectl get nodes
NAME                             STATUS   ROLES    AGE   VERSION
ip-192-168-104-74.ec2.internal   Ready    <none>   34m   v1.28.1-eks-43840fb
ip-192-168-71-34.ec2.internal    Ready    <none>   34m   v1.28.1-eks-43840fb
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
pod/nginx-deployment-598bb489bf-jp7sq   1/1     Running   0          10s
pod/nginx-deployment-598bb489bf-wqwbj   1/1     Running   0          10s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   2/2     2            2           12s

NAME                                            REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/nginx-hpa   Deployment/nginx-deployment   <unknown>/80%   2         10        0          11s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
service/kubernetes      ClusterIP   10.100.0.1      <none>        443/TCP        45m
service/nginx-service   NodePort    10.100.26.244   <none>        80:30747/TCP   10s

NAME                                      CLASS   HOSTS                ADDRESS   PORTS   AGE
ingress.networking.k8s.io/nginx-ingress   alb     entry1.example.com             80      11s
```

### Goal 3: Find out why Application Load Balancer (ALB) not working?

```sh
% kubectl get ingress nginx-ingress
NAME            CLASS   HOSTS                ADDRESS   PORTS   AGE
nginx-ingress   alb     entry1.example.com             80      35s # <-------- no address shown, why?
```

After fixing the issue, you should be able to see command output as follow,

```sh
% kubectl get ingress nginx-ingress
NAME            CLASS   HOSTS                ADDRESS                                                                  PORTS   AGE
nginx-ingress   alb     entry1.example.com   k8s-default-nginxing-XXXXXXXXXX-XXXXXXXXXX.us-east-1.elb.amazonaws.com   80      2m41s
```

Once the Load Balancer is created, you should be able to visit the application via the endpoint of load balancer with default `HTTP` protocol.

### Goal 4: Find out why Horizontal Pod Autoscaling (HPA) not working?

```sh
% kubectl get hpa nginx-hpa
NAME        REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   <unknown>/80%   2         10        2          2m57s
```

Did you aware that HPA is not working... why? :thinking:

After you fixed the HPA issue, it should shown as follow

```sh
% kubectl get hpa nginx-hpa
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   2%/80%    2         10        2          7m34s
```

### Goal 5: HPA is working. Now I want to set Nginx replicas with `kubectl scale ...` but failed. Why?

```sh
% kubectl scale --replicas 12 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
```

Why the Pod count not able to reach desired pod count `12` but quickly scale down back to `2`... why is that ?

### Goal 6: Remove HPA and try to scale to `40` manually

```sh
% kubectl delete hpa nginx-hpa
horizontalpodautoscaler.autoscaling "nginx-hpa" deleted
```

```sh
% kubectl scale --replicas 40 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
```

```sh
% kubectl get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   25/40   40           25          10m <-------- stock at "25/40" ...why?
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
... (omitted)
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
