# eks-tutorials

Step by step tutorial for those who have zero knowledge to Amazon EKS.

## Disclaimer

* The project here is for demonstration purpose only.

* **_DO NOT_** blindly apply it to your production environments.

* Only [Standard Support versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html#kubernetes-release-calendar) will be covered.

## Prerequisites

- [eksctl](https://eksctl.io/) - The official CLI for Amazon EKS
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - The Kubernetes command-line tool
- [helm](https://helm.sh/) - The Kubernetes Package Manage

### Assumptions

- Your AWS Profile have proper permission configured.
- All the tools required were setup properly
- All the resources are under `us-east-1`
- The cluster name would be `eks-auto-mode`

## Guideline of the tutorial

- Goal 1: Create EKS Cluster with `eksctl`
- Goal 2: Deploy workload and make sure Auto Mode work as expeceted
- Goal 3: Figure out why HPA and Ingress not working?
- Goal 4: Fix the issues
- Goal 5: Figure out why `kubectl scale ...` would failed
- Goal 6: Try to turn ALB entry from HTTP to HTTPS
- Goal 7: How to switch to Network Load Balancer (NLB)?
- Goal 8: Cleanup


### Goal 1: Create EKS Cluster with `eksctl`

Make sure you have latest `eksctl` installed and you should be able to create EKS cluster with minimal setup as follow.

```sh
% eksctl create cluster -f ./cluster-config/cluster-auto.yaml
```

OR (only when `accessEntries` not empty)

```sh
% cat cluster-config/cluster-auto.yaml | \
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output json --query "Account" | sed 's/"//g') envsubst '${AWS_ACCOUNT_ID}' | \
    TARGET_ROLE_NAME=DemoRole envsubst '${TARGET_ROLE_NAME}' | eksctl create cluster -f -
```

<details>
<summary>Click here to show sample deployment output :mag:</summary>

```
2025-XX-XX XX:XX:XX [ℹ]  eksctl version 0.207.0
2025-XX-XX XX:XX:XX [ℹ]  using region us-east-1
2025-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1a - public:192.168.0.0/19 private:192.168.64.0/19
2025-XX-XX XX:XX:XX [ℹ]  subnets for us-east-1b - public:192.168.32.0/19 private:192.168.96.0/19
2025-XX-XX XX:XX:XX [ℹ]  using Kubernetes version 1.32
2025-XX-XX XX:XX:XX [ℹ]  creating EKS cluster "eks-auto-mode" in "us-east-1" region with
2025-XX-XX XX:XX:XX [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=us-east-1 --cluster=eks-auto-mode'
2025-XX-XX XX:XX:XX [ℹ]  Kubernetes API endpoint access will use provided values {publicAccess=true, privateAccess=true} for cluster "eks-auto-mode" in "us-east-1"
2025-XX-XX XX:XX:XX [ℹ]  configuring CloudWatch logging for cluster "eks-auto-mode" in "us-east-1" (enabled types: api, audit, authenticator, controllerManager, scheduler & no types disabled)
2025-XX-XX XX:XX:XX [ℹ]  default addons metrics-server were not specified, will install them as EKS addons
2025-XX-XX XX:XX:XX [ℹ]
2 sequential tasks: { create cluster control plane "eks-auto-mode",
    3 sequential sub-tasks: {
        1 task: { create addons },
        wait for control plane to become ready,
        update CloudWatch log retention,
    }
}
2025-XX-XX XX:XX:XX [ℹ]  building cluster stack "eksctl-eks-auto-mode-cluster"
2025-XX-XX XX:XX:XX [ℹ]  deploying stack "eksctl-eks-auto-mode-cluster"
2025-XX-XX XX:XX:XX [ℹ]  waiting for CloudFormation stack "eksctl-eks-auto-mode-cluster"
2025-XX-XX XX:XX:XX [ℹ]  creating addon: metrics-server
2025-XX-XX XX:XX:XX [ℹ]  successfully created addon: metrics-server
2025-XX-XX XX:XX:XX [ℹ]  set log retention to 90 days for CloudWatch logging
2025-XX-XX XX:XX:XX [ℹ]  waiting for the control plane to become ready
2025-XX-XX XX:XX:XX [✔]  saved kubeconfig as "/Users/demoUser/.kube/config"
2025-XX-XX XX:XX:XX [ℹ]  no tasks
2025-XX-XX XX:XX:XX [✔]  all EKS cluster resources for "eks-auto-mode" have been created
2025-XX-XX XX:XX:XX [ℹ]  kubectl command should work with "/Users/demoUser/.kube/config", try 'kubectl get nodes'
2025-XX-XX XX:XX:XX [✔]  EKS cluster "eks-auto-mode" in "us-east-1" region is ready
```
</details>

Verify there have no EKS node running initially.

```sh
% kubectl get nodes
No resources found # expected, since we are running Auto Mode enabled cluster.
```

***NOTE*** For eksctl version higher than [v0.201.0](https://github.com/eksctl-io/eksctl/releases/tag/v0.201.0), you should find there have 1 node created, since `metrics-server` [became default addon for eksctl created cluster](https://github.com/eksctl-io/eksctl/pull/8118).

### Goal 2: Deploy workload and make sure Auto Mode work as expeceted

At this stage, you would need to have `kubectl` installed. Then you should be able to create `Deployment`, `HPA`, `Service` and `Ingress` resources.

```sh
% kubectl apply -f ./examples/simple/
deployment.apps/nginx-deployment created
horizontalpodautoscaler.autoscaling/nginx-hpa created
ingress.networking.k8s.io/nginx-ingress created
service/nginx-service created
```

After workload deployed, there should have node provisioned by Auto Node after few seconds wait.

```sh
% kubectl get nodes -L "eks.amazonaws.com/compute-type"
NAME                  STATUS   ROLES    AGE   VERSION               COMPUTE-TYPE
i-00f395d014ff8e657   Ready    <none>   11s   v1.32.0-eks-2e66e76   auto
```

### Goal 3: Figure out why HPA and Ingress not working?

```sh
% kubectl get pods,deployments,hpa,service,ingress
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-54697596c9-7bc4f   1/1     Running   0          22s
pod/nginx-deployment-54697596c9-gqpv5   1/1     Running   0          22s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   2/2     2            2           22s

NAME                                            REFERENCE                     TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/nginx-hpa   Deployment/nginx-deployment   cpu: <unknown>/80%   2         10        2          22s # <-------- why no metrics?

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
service/kubernetes      ClusterIP   10.100.0.1       <none>        443/TCP        12m
service/nginx-service   NodePort    10.100.137.151   <none>        80:30928/TCP   21s

NAME                                      CLASS   HOSTS                ADDRESS   PORTS   AGE
ingress.networking.k8s.io/nginx-ingress   alb     entry1.example.com             80      22s # <-------- no address shown, why?
```

### Goal 4: Fix the issues

After fixing the issue, you should be able to see command output as follow,

```sh
% kubectl get ingress nginx-ingress
NAME            CLASS   HOSTS                ADDRESS                                    PORTS   AGE
nginx-ingress   alb     entry1.example.com   k8s-default-XXX.REGION.elb.amazonaws.com   80      60s
```

After fixing HPA issue, you should be able to see command output as follow,

```sh
% kubectl get hpa nginx-hpa
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   2%/80%    2         10        2          2m7s
```

### Goal 5: Figure out why `kubectl scale ...` would failed

```sh
% kubectl scale --replicas 12 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
```

Why the Pod count not able to reach desired pod count `12` but quickly scale down back to `2`... why is that ?

### Goal 6: Try to turn ALB entry from HTTP to HTTPS

Service with `HTTP` is clearly unsafe, how to made it safe with `HTTPS`?

### Goal 7: How to switch to Network Load Balancer (NLB)?

If you solve can provision ALB then you should be able to create NLB as well. But how...? :thinking:

### Goal 8: Cleanup

Terminate all resources that we created earlier.

```sh
% kubectl delete -f ./examples/simple/ --ignore-not-found
```

Terminate the EKS cluster

:warning: **_WARNING: all resources will be removed permanently, unrecoverable_**

```sh
% eksctl delete cluster -f ./cluster-config/cluster-auto.yaml
```

**OPTIONAL** Cleanup IAM User/Role/Policy and [Identity Provider (IdP)](https://console.aws.amazon.com/iamv2/home?#/identity_providers) with care.

### Bonus

There's another repository with common used addons installation scripts:

- https://github.com/guessi/eks-integrations-quick-start
