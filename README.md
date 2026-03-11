# eks-tutorials

Step by step tutorial for those who have zero knowledge to Amazon EKS.

## Disclaimer

- The project here is for demonstration purpose only.

- **_DO NOT_** blindly apply it to your production environments.

## Prerequisites

- [eksctl](https://docs.aws.amazon.com/eks/latest/eksctl/what-is-eksctl.html) - The official CLI for Amazon EKS
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - The Kubernetes command-line tool

### Assumptions

- Your AWS Profile have proper permission configured.
- All the tools required were setup properly
- All the resources are under `us-east-1`
- The cluster name would be `eks-auto-mode`

## Cluster configurations

This tutorial only uses `cluster-config/cluster-auto.yaml`, but the
`cluster-config/` directory ships several ready-to-adapt variants:

| Config file               | Use case                                                                                                                                                                                                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `cluster-auto.yaml`       | EKS Auto Mode cluster used throughout this tutorial; compute, storage and load balancing are managed by EKS.                                                                                                                                                       |
| `cluster-minimal.yaml`    | Classic cluster reference: three managed node groups (AL2023, Bottlerocket, Windows) plus kube-proxy / vpc-cni / coredns / pod-identity-agent / metrics-server addons.                                                                                            |
| `cluster-full.yaml`       | Batteries-included reference: Auto Mode (empty nodePools) with one active AL2023 managed node group, plus observability / metrics-server / network-flow-monitor / EBS CSI addons and many commented node-group variants (Bottlerocket, Windows, self-managed spot). |
| `cluster-private.yaml`    | Fully private cluster (`privateCluster.enabled: true`) with no public API endpoint.                                                                                                                                                                                |
| `cluster-ipv6.yaml`       | IPv6 cluster (`ipFamily: IPv6`) including the extra VPC CNI IAM permissions IPv6 requires.                                                                                                                                                                         |
| `cluster-local-zone.yaml` | Template for running self-managed nodes in an AWS Local Zone (requires a pre-existing VPC; see the warning at the top of the file).                                                                                                                                |

> **EKS version:** every config pins `version: "1.35"`. If that version is outside the supported EKS window when you run it, `eksctl` will fail to create the cluster — bump it to a currently supported version first.
>
> **Cost:** several configs set `nat.gateway: HighlyAvailable` (one NAT gateway per AZ) and `enableDetailedMonitoring: true`; both incur ongoing charges. For a throwaway demo, use `nat.gateway: Single` and drop detailed monitoring.

## Guideline of the tutorial

- Goal 1: Create EKS Cluster with `eksctl`
- Goal 2: Deploy workload and make sure Auto Mode work as expected
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

Verify there have no EKS node running initially.

```sh
% kubectl get nodes
No resources found # expected, since we are running Auto Mode enabled cluster.
```

_**NOTE**_ `metrics-server` is explicitly installed as an addon in `cluster-auto.yaml`. If you are adapting this config and remove it, you will need to install it manually before HPA metrics will work.

### Goal 2: Deploy workload and make sure Auto Mode work as expected

At this stage, you would need to have `kubectl` installed. Then you should be able to create `Deployment`, `HPA`, `Service` and `Ingress` resources.

```sh
% kubectl apply -f ./examples/nginx-sample/
service/nginx-service created
ingress.networking.k8s.io/nginx-ingress created
deployment.apps/nginx-deployment created
horizontalpodautoscaler.autoscaling/nginx-hpa created
```

After workload deployed, there should have node provisioned by Auto Node after about a minute.

```sh
% kubectl get nodes -L "eks.amazonaws.com/compute-type"
NAME                  STATUS   ROLES    AGE   VERSION               COMPUTE-TYPE
i-EXAMPLE1234567890   Ready    <none>   11s   v1.35.x-eks-1234567   auto
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

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/kubernetes      ClusterIP   10.100.0.1       <none>        443/TCP   12m
service/nginx-service   ClusterIP   10.100.137.151   <none>        80/TCP    21s

NAME                                      CLASS   HOSTS                ADDRESS   PORTS   AGE
ingress.networking.k8s.io/nginx-ingress   alb     entry1.example.com             80      22s # <-------- no address shown, why?
```

### Goal 4: Fix the issues

> **Hint:** EKS Auto Mode does not create a default `alb` IngressClass for you, which is why `nginx-ingress` shows no `ADDRESS`. The `alb` `IngressClass` / `IngressClassParams` the Ingress needs are defined in `./examples/auto-mode/auto-ingress.yaml` — apply it with `kubectl apply -f ./examples/auto-mode/auto-ingress.yaml`. If you also want to manage your own storage class or node pools instead of the Auto Mode defaults, see `./examples/auto-mode/auto-storage.yaml` and `./examples/auto-mode/auto-node.yaml` (remember to replace the placeholder security group / subnet values first).

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

> **Hint:** the HPA reports `cpu: <unknown>` for two reasons. First, the metric pipeline must exist — `metrics-server` is installed as an addon in `cluster-auto.yaml`; confirm it is running with `kubectl get deploy metrics-server -n kube-system`. Second, CPU `Utilization` is measured as a percentage of the container's CPU _request_, and the `resources:` block in `./examples/nginx-sample/deployment.yaml` is commented out — uncomment it and re-apply with `kubectl apply -f ./examples/nginx-sample/deployment.yaml`.

### Goal 5: Figure out why `kubectl scale ...` would failed

```sh
% kubectl scale --replicas 12 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
```

Why the Pod count not able to reach desired pod count `12` but eventually scale back down to `2`... why is that ?

> **Hint:** The HPA is still active and owns the replica count. `kubectl scale` to 12 is immediately clamped to `maxReplicas: 10` by the HPA controller. Then, because CPU utilization is low, the HPA scales back down to `minReplicas: 2` after the scale-down stabilization window (default 5 minutes). To scale beyond 10, increase `maxReplicas` in the HPA. To take manual control of replicas, delete the HPA first — there is no built-in suspend field in `autoscaling/v2`.

### Goal 6: Try to turn ALB entry from HTTP to HTTPS

Service with `HTTP` is clearly unsafe, how to make it safe with `HTTPS`?

> **Hint:** On EKS Auto Mode the ALB controller is built-in and certificate configuration is done through `IngressClassParams` (`spec.certificateARNs`), not Ingress annotations. For SSL redirect, use an `alb.ingress.kubernetes.io/actions.*` annotation on the Ingress resource itself — individual Ingress annotations are still supported on Auto Mode for behavior customization, just not for IngressClass-level configuration. The `alb.ingress.kubernetes.io/certificate-arn`, `alb.ingress.kubernetes.io/listen-ports`, and `alb.ingress.kubernetes.io/ssl-redirect` annotations shown in `./examples/nginx-sample/alb.yaml` are for the self-managed AWS Load Balancer Controller and are **not supported** on Auto Mode; configure certificates via `IngressClassParams` instead.

### Goal 7: How to switch to Network Load Balancer (NLB)?

If you can provision an ALB, then you should be able to create an NLB as well. But how...? :thinking:

> **Hint:** A `LoadBalancer` Service with the NLB annotations is provided (commented out) in `./examples/nginx-sample/nlb.yaml`. On EKS Auto Mode it must set `spec.loadBalancerClass: eks.amazonaws.com/nlb` (already in the file) or the Service stays `<pending>` forever. It reuses the name `nginx-service`, so it replaces the ClusterIP Service (`service.yaml`) and the ALB Ingress (`alb.yaml`) rather than running alongside them — delete those two first, then apply `nlb.yaml` (the file header lists the exact steps). Note: Classic ELB (`./examples/nginx-sample/clb.yaml`) is **not** supported on Auto Mode; it only works on a classic cluster such as `cluster-config/cluster-minimal.yaml`.

### Goal 8: Cleanup

Terminate all resources that we created earlier.

```sh
% kubectl delete -f ./examples/nginx-sample/ --ignore-not-found
```

Terminate the EKS cluster

:warning: **_WARNING: all resources will be removed permanently, unrecoverable_**

```sh
% eksctl delete cluster -f ./cluster-config/cluster-auto.yaml
```

**OPTIONAL** Cleanup IAM User/Role/Policy and [Identity Provider (IdP)](https://console.aws.amazon.com/iam/home#/identity_providers) with care.

### Bonus

Need a lightweight, always-on Pod to force a node to provision or to `kubectl exec` into for debugging? Use the keepalive workload in `./examples/troubleshooting/al2023-deployment.yaml`:

```sh
% kubectl apply -f ./examples/troubleshooting/al2023-deployment.yaml
```

There's another repository with common used addons installation scripts:

- <https://github.com/guessi/eks-integrations-quick-start>
