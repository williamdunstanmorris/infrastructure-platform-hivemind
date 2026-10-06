# <Project name>

## Overview
- This repo deploys the app `./greeter` to Kubernetes, hosted on AWS. It is provided on my own domain, `https://subcloudlabs.com/`
- Kubernetes is hosted using EKS, with its own dedicated AWS ALB LB Controller.
- Terraform modules were bespoke written, and sectioned according to how they would scale globally.
- Traffic flows through Route53 → LB/ingress → service → pod

# High availability & production-ready
- This aims to be production-ready and highly available. Therefore, multi-AZ, replicas, PodDisruptionBudgets, health probes, live-ness probes, EKS auto mode: topologySpreadConstraints, de-registration delay, pod readiness gates are in effect.

## Prerequisites
- Please make sure you have an AWS account and the appropriate permissions to apply Terraform. (AdministratorAccess or similar). With expansion, IAM boundaries could be used to avoid exessive permissions.
- Please make sure you have a set of baseline tools installed (terraform, aws cli, kubectl, helm, go, docker, cURL).
- !!! Connecting to K8: Because this is AWS-centric, and to avoid overhead for configuring Bastion inbound firewall rules, AWS Systems Manager Session Manager is used here to access the Kubernetes Cluster + Kubernetes API. You can install it [here](https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html).

## Repository Layout

There are three core directories. The `infrastructure` directory and the `platform` directory each have differing terraform states. sectioned according to good pattern practices. The infrastructure is responsible for all core necessary infrastructure, and the platform is dedicated to provisioning baseline cluster necessities, like ArgoCD. You could expand this to include other helm charts, like Grafana, Prometheus and other EKS administration tooling to expand the internal developer platform too. The `apps` directory is where all app configuration lives.
```
.
├── apps                  # App manifest
├── infrastructure        # Core infrastructure 
│   └── modules
│       ├── aws-bastion   # Connectivity. EKS is private-subnetted, AWS Session Manager with a private VPC endpoint to connect via IAM.
│       ├── aws-dns       # DNS
│       ├── aws-eks       # EKS, addons, node-groups, IAM
│       └── aws-network   # VPC, Multi-az, private+public subnets, Route Tables, NAT G, IG
└── platform              # Platform Infrastructure, Github App Repo,
```
* With child modules for terraform, it is advised to track them separately in their own versioned repo, and reference them. This would make them reusable and assist with keeping in D.R.Y
## Getting Started / Deployment

Make sure you have run `aws configure`. Going forward, AWSCLI and Terraform Providers are based on the AWS_PROFILE `--profile hivemind` flag if you have multiple AWS Organisations.

To apply infrastructure: 
```
cd infrastructure
terraform init
terraform apply
```
To provision the EKS cluster, you need to have a connection to EKS, which goes through a bastion host using AWS SSM Session Manager. This script updates and sets your kubeconfig, and creates a connection to the EKS cluster. In a new terminal:
```
cd platform && ./connect.sh
```
Keep this window open to continue running any subsequent `kubectl`, `eksctl`, `helm` command tools that require connecting directly to the cluster. 
ArgoCD is installed on the cluster via Helm and managed with Terraform. Connect to it and access localhost:8080 on your browser. The temporary access is username: `admin` and password: `changeme123`
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Using the Service
- The service exists as
- To hit the endpoint, I have created a dedicated https endpoint for this solution.
```
curl -sS -i "https://hivemind.subcloudlabs.com/"
```
- The ALB is created through the Kubernetes Ingress Object that is interacting with AWS ALB resources. It automatically resolves DNS upon recreation. I did this to remove future TLS and HTTP(s) connectivity overhead that is better handled with Terraform / AWS ACM. You can just focus on creating services without worrying about TLS now.
- You could expand this by additional authentication on the ALB Load Balancer. Doing so would stop unwanted requests from entering Kubernetes.
- You could expand this by adding WAF to the ALB for extra protection.
- Utilising AWS ALB here has the advantage of not having an already-prescribed ACM certificate with AWS. Less Kubernetes overhead.
How do you hit the endpoint? Example curl and expected output.
- What does the new URL parameter do? Example with and without it.
- How is HELLO_TAG set, and why is that value unique? (config, not hardcoded in the image)

## CI/CD Pipeline
- What triggers it? What are the stages (lint, test, build, scan, push, plan, deploy)?
- Where do images go (ECR), and how are they tagged?
- How does the pipeline authenticate to AWS? (OIDC vs static keys)
- Rollback story: how do you revert a bad deploy?
- What gates exist before prod (approval on apply, plan output on PRs)?

## Security
- Network: private subnets, security groups, what is publicly exposed.
- IAM: least privilege, IRSA/Pod Identity, no long-lived creds.
- Container: non-root, minimal base image, image scanning.
- Secrets handling, TLS/certs (ACM), encryption at rest for state and cluster.

## Reliability & Performance
- Autoscaling (HPA, node scaling), resource requests/limits.
- Probes, rolling update strategy, graceful shutdown.
- Observability: logs, metrics, alerts. What's in place vs. what you'd add?

## Cost Considerations
- What costs money here (NAT gateways, EKS control plane, LB)?
- How do you tear it down? (`terraform destroy` and any gotchas)

## Tradeoffs & Limitations
- What did you cut or simplify due to time or the environment, and why?
- Be explicit. They asked for this and said it's valued.

## What I'd Do in Production
- For each limitation above: what would you do with more time or a real environment?
  (multi-env, WAF, GitOps with ArgoCD/Flux, policy as code, DR, backups, SLOs)

## Troubleshooting
- Two or three failure modes you actually hit and how you fixed them.

## Cleanup
- Exact steps to destroy everything and confirm nothing is left billing.

## Availability Targets (SLOs)
- What SLO did you pick (e.g. 99.9%), and what does it imply for design?
- How is it measured, and what alerts fire on it?

## Failure Mode Analysis
- Table: failure → blast radius → automatic response → recovery time
  (pod crash, node loss, AZ loss, bad deploy, ALB target failure, expired cert, region outage)
- Which of these did you actually test? (link the evidence)

## Resilience Testing
- Exactly what you did: delete pods under load, drain a node, simulate AZ loss
  (cordon/drain all nodes in one AZ), bad image rollout → rollback.
- Results: error rate and latency during each test.

## Scaling & Load Test Results
- Tool and method (k6/hey), traffic profile, and how you scaled.
- When did HPA trigger, how long did new pods and nodes take, and what was the limiting factor?
- Graph or numbers. Even a screenshot works.

## Security Posture
- Short threat model: what are you protecting, from whom?
- Controls mapped to layers (network, identity, workload, supply chain, data).

## Decision Log
- Short ADR-style entries: EKS vs ECS, Karpenter vs CA, ALB vs NLB+ingress-nginx,
  NAT per AZ vs single, module choices. Context → decision → consequence.

## Cost Estimate
- Rough monthly cost table (EKS control plane, nodes, NAT, ALB) and the levers to reduce it.

## Operations Runbook
- Deploy, rollback, rotate, scale manually, debug a failing pod, break-glass access.

## Testing & Validation
- What runs in CI vs what you ran manually. How a reviewer can verify your claims quickly.

## Future Improvements
- Tier 3 items with a short design for each (multi-region, GitOps, policy as code, DR).