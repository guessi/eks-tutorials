# eks-tutorials

Step by step tutorial for who have no experience to Amazon EKS. After finished the tutorial, you should be able to run general workload with Amazon EKS. Hope you enjoy the journey.

### Disclaimer

Please note this tutorial is for demonstration purpose only, please **_DO NOT_** blindly apply it to your production environments.

## Prerequisites

- [eksctl](https://eksctl.io/) - The official CLI for Amazon EKS
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - The Kubernetes command-line tool
- [helm](https://helm.sh/) - The Kubernetes Package Manage

### Assumptions

- An AWS profile existed with name `default`, and `AdministratorAccess` permission configured
- All the tools required were setup properly
- All the resources are under `us-east-1`
- The cluster name would be `eks-demo`

## Guideline of the tutorial

- Goal 1: Create EKS Cluster
- Goal 2: Deploy nginx with Application Load Balancer (ALB)
- Goal 3: Find out why Application Load Balancer (ALB) not working?
- Goal 4: Find out why Horizontal Pod Autoscaling (HPA) not working?
- Goal 5: HPA is working. Now I want to set Nginx replicas with `kubectl scale ...` but failed. Why?
- Goal 6: Try to scale to `20`
- Goal 7: Try to turn ALB entry from HTTP to HTTPS
- Goal 8: How to switch to Network Load Balancer (NLB)?
- Goal 9: Deployment a Pod with Persistent Volume
- Goal 10: Store data externally
- Goal 11: Cleanup


### Goal 1: Create EKS Cluster

Make sure you have latest `eksctl` installed and you should be able to create EKS cluster with minimal setup as follow.

```sh
% eksctl create cluster -f ./cluster-config/cluster-minimal.yaml
```

<details>
<summary>Click here to show sample deployment output :mag:</summary>

```
2022-XX-XX XX:XX:XX [ℹ]  eksctl version 0.100.0
2022-XX-XX XX:XX:XX [ℹ]  using region us-east-1
2022-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1a - public:192.168.0.0/19 private:192.168.64.0/19
2022-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1b - public:192.168.32.0/19 private:192.168.96.0/19
2022-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" will use "" [AmazonLinux2/1.22]
2022-XX-XX XX:XX:XX [ℹ]  using Kubernetes version 1.22
2022-XX-XX XX:XX:XX [ℹ]  creating EKS cluster "eks-demo" in "us-east-1" region with managed nodes
2022-XX-XX XX:XX:XX [ℹ]  1 nodegroup (mng-1) was included (based on the include/exclude rules)
2022-XX-XX XX:XX:XX [ℹ]  will create a CloudFormation stack for cluster itself and 0 nodegroup stack(s)
2022-XX-XX XX:XX:XX [ℹ]  will create a CloudFormation stack for cluster itself and 1 managed nodegroup stack(s)
2022-XX-XX XX:XX:XX [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-east-1 --cluster=eks-demo'
2022-XX-XX XX:XX:XX [ℹ]  Kubernetes API endpoint access will use default of {publicAccess=true, privateAccess=false} for cluster "eks-demo" in "us-east-1"
2022-XX-XX XX:XX:XX [ℹ]  configuring CloudWatch logging for cluster "eks-demo" in "us-east-1" (enabled types: api, audit, authenticator, controllerManager, scheduler & no types disabled)
2022-XX-XX XX:XX:XX [ℹ]
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
2022-XX-XX XX:XX:XX [ℹ]  building cluster stack "eksctl-eks-demo-cluster"
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-cluster"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2022-XX-XX XX:XX:XX [ℹ]  set log retention to 90 days for CloudWatch logging
2022-XX-XX XX:XX:XX [ℹ]  building iamserviceaccount stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-addon-iamserviceaccount-kube-system-aws-node"
2022-XX-XX XX:XX:XX [ℹ]  serviceaccount "kube-system/aws-node" already exists
2022-XX-XX XX:XX:XX [ℹ]  updated serviceaccount "kube-system/aws-node"
2022-XX-XX XX:XX:XX [ℹ]  daemonset "kube-system/aws-node" restarted
2022-XX-XX XX:XX:XX [ℹ]  building managed nodegroup stack "eksctl-eks-demo-nodegroup-mng-1"
2022-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-demo-nodegroup-mng-1"
2022-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-nodegroup-mng-1"
2022-XX-XX XX:XX:XX [✔]  saved kubeconfig as "/Users/demoUser/.kube/config"
2022-XX-XX XX:XX:XX [ℹ]  no tasks
2022-XX-XX XX:XX:XX [✔]  all EKS cluster resources for "eks-demo" have been created
2022-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" has 2 node(s)
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-125-105.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-69-255.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  waiting for at least 2 node(s) to become ready in "mng-1"
2022-XX-XX XX:XX:XX [ℹ]  nodegroup "mng-1" has 2 node(s)
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-125-105.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  node "ip-192-168-69-255.ec2.internal" is ready
2022-XX-XX XX:XX:XX [ℹ]  kubectl command should work with "/Users/demoUser/.kube/config", try 'kubectl get nodes'
2022-XX-XX XX:XX:XX [✔]  EKS cluster "eks-demo" in "us-east-1" region is ready
```
</details>

Verify the EKS nodes are running.

```sh
% kubectl get nodes
NAME                              STATUS   ROLES    AGE     VERSION
ip-192-168-125-105.ec2.internal   Ready    <none>   2m18s   v1.22.6-eks-7d68063
ip-192-168-69-255.ec2.internal    Ready    <none>   2m27s   v1.22.6-eks-7d68063
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
pod/nginx-deployment-7966d896c8-2fw82   1/1     Running   0          26s
pod/nginx-deployment-7966d896c8-f276s   1/1     Running   0          26s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   2/2     2            2           29s

NAME                                            REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/nginx-hpa   Deployment/nginx-deployment   <unknown>/80%   2         10        2          29s

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/kubernetes      ClusterIP   10.100.0.1       <none>        443/TCP        12m
service/nginx-service   NodePort    10.100.140.137   <none>        80:30050/TCP   28s

NAME                                      CLASS    HOSTS                ADDRESS   PORTS   AGE
ingress.networking.k8s.io/nginx-ingress   <none>   entry1.example.com             80      31s
```

### Goal 3: Find out why Application Load Balancer (ALB) not working?

```sh
% kubectl get ingress nginx-ingress
NAME            CLASS    HOSTS                ADDRESS   PORTS   AGE
nginx-ingress   <none>   entry1.example.com             80      81s # <-------- why?
```

After fixing the issue, you should be able to see command output as follow,

```sh
% kubectl get ingress nginx-ingress
NAME            CLASS    HOSTS                ADDRESS                                                                 PORTS   AGE
nginx-ingress   <none>   entry1.example.com   k8s-default-nginxing-XXXXXXXXXX-XXXXXXXXX.us-east-1.elb.amazonaws.com   80      4m39s
```

Once the Load Balancer is created, you should be able to visit the application via the endpoint of load balancer with default `HTTP` protocol.

### Goal 4: Find out why Horizontal Pod Autoscaling (HPA) not working?

```sh
% kubectl get hpa nginx-hpa
NAME        REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   <unknown>/80%   2         10        2          29s
```

Did you aware that HPA is not working... why? :thinking:

### Goal 5: HPA is working. Now I want to set Nginx replicas with `kubectl scale ...` but failed. Why?

```sh
% kubectl scale --replicas 12 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
```

Why the Pod count not able to reach desired pod count `12` but quickly scale down back to `10`... why is that ?

### Goal 6: Try to scale to `20`

```sh
% kubectl get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   13/20   20           13          31m # <-------- stock at "13/20" ...why?
```

```sh
% kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7966d896c8-4mjsh   0/1     Pending   0          60s # <-------- not running
nginx-deployment-7966d896c8-7568r   0/1     Pending   0          60s # <-------- not running
nginx-deployment-7966d896c8-75rq9   1/1     Running   0          60s
nginx-deployment-7966d896c8-7php6   1/1     Running   0          60s
nginx-deployment-7966d896c8-99g54   0/1     Pending   0          60s # <-------- not running
nginx-deployment-7966d896c8-ccdw8   1/1     Running   0          60s
nginx-deployment-7966d896c8-d6h6t   0/1     Pending   0          60s # <-------- not running
nginx-deployment-7966d896c8-grmll   1/1     Running   0          61s
nginx-deployment-7966d896c8-ktfs9   1/1     Running   0          20m
nginx-deployment-7966d896c8-ph95q   1/1     Running   0          60s
nginx-deployment-7966d896c8-pt7x4   1/1     Running   0          60s
nginx-deployment-7966d896c8-q475q   0/1     Pending   0          60s # <-------- not running
nginx-deployment-7966d896c8-qq8mh   1/1     Running   0          60s
nginx-deployment-7966d896c8-r75hj   1/1     Running   0          60s
nginx-deployment-7966d896c8-rqpbk   0/1     Pending   0          60s # <-------- not running
nginx-deployment-7966d896c8-sw6bt   0/1     Pending   0          60s # <-------- not running
nginx-deployment-7966d896c8-tfxch   1/1     Running   0          20m
nginx-deployment-7966d896c8-tngnm   1/1     Running   0          60s
nginx-deployment-7966d896c8-wk6ct   1/1     Running   0          60s
nginx-deployment-7966d896c8-xxsq9   1/1     Running   0          60s
```

### Goal 7: Try to turn ALB entry from HTTP to HTTPS

Service with `HTTP` is clearly unsafe, how to made it safe with `HTTPS`?

### Goal 8: How to switch to Network Load Balancer (NLB)?

If you solve can provision ALB then you should be able to create NLB as well. But how...? :thinking:

### Goal 9: Deployment a Pod with Persistent Volume

Pods are stateless by default, how to preserve data with Persistent Volume?

### Goal 10: Store data externally

What about accessing data storage over network?

### Goal 11: Cleanup

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

<details>
<summary>Click here for bonus :mag:</summary>

You may find some useful installation scripts for install addons to your cluster under "./scripts" folder.

#### Supported Addons:

- AWS EBS CSI Driver
- AWS EFS CSI Driver
- AWS FSx CSI Driver
- AWS Load Balancer Controller
- Cluster AutoScaler
- Metrics Server
</details>
