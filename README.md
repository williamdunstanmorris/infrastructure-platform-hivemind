# Hivemind Greeter

Hey! This is my solution to your challenge! 

## Some Closing Solution Notes
* Overall, this works well, and is a almost-production-grade system in regard to the AWS (e.g. Security Posture). But it needs more time & work (e.g. Kubernetes / GitOps app management)
* 70% of the time was spent configuring AWS, setting up VPC, Subnets, Route Tables, Route53, Bastion, administration of EKS, Helm, and ArgoCD. 30% of the time was spent on the actual deployment of the app itself.
* Please don't steal my work. These are a lot of my code & industry-experiences and insights / ideas over the last decade I accumulated have given in code here. Please respect :)
* I inserted a little easter egg into this solution somewhere, it's not too hard to find.

This repo deploys the app `./greeter` to Kubernetes, hosted on AWS. It is provided on my own personal domain. 
```
https://hivemind.subcloudlabs.com/
```
- Kubernetes is hosted on EKS, with its own dedicated AWS ALB LB Controller.
- Terraform modules were bespoke written, and sectioned according to how they would scale globally.
- Traffic flows through Route53 → LB/ingress → service → pod

# High availability & production-ready

This aims to be production-ready and highly available. Therefore, 
- Multi-AZ, 
- Node Group Scaling
- Replicas 
- PodDisruptionBudgets (WIP)
- Health Probes
- Live-ness probes 
- (WIP) EKS auto mode: topologySpreadConstraints, de-registration delay, pod readiness gates are in effect.
- Please note: Not all of these were able to be deployed in time. But this was the direction.

## Prerequisites
1. Make sure you have an AWS account and the appropriate permissions to apply Terraform. (AdministratorAccess or similar). With expansion, IAM boundaries could be used to avoid exessive permissions.
2. Please make sure you have a set of baseline tools installed (terraform, aws cli, kubectl, helm, go, docker, cURL).
3. Connecting to K8: Because this is AWS-centric, and to avoid overhead for configuring Bastion inbound firewall rules, AWS Systems Manager Session Manager is used here to access the Kubernetes Cluster + Kubernetes API. You can install it [here](https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html).

## Repository Layout

There are three core directories. The `infrastructure` directory and the `platform` directory each have differing terraform states. sectioned according to good pattern practices. The infrastructure is responsible for all core necessary infrastructure, and the platform is dedicated to provisioning baseline cluster necessities, like ArgoCD. You could expand this to include other helm charts, like Grafana, Prometheus and other EKS administration tooling to expand the internal developer platform too. The `apps` directory is where all app configuration lives.
```
.
├── app                   # App source code and ApplicationSpec manifest
├── infrastructure        # Core infrastructure 
│   └── modules
│       ├── aws-bastion   # Connectivity. EKS is private-subnetted, AWS Session Manager with a private VPC endpoint to connect via IAM.
│       ├── aws-dns       # DNS Records, ACM 
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
```
cd platform
terraform init
terraform apply
```
ArgoCD is installed on the cluster via Helm and managed with Terraform. Connect to it and access localhost:8080 on your browser. The temporary access is username: `admin` and password: `changeme123`
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Using the Service

To hit the endpoint, I have created a dedicated HTTP(s) endpoint domain for this solution.
```
❯ curl "https://hivemind.subcloudlabs.com/"

Hello, World (94.139.29.44)! I'm hivemind-deployment-7b7697f44-dq6zh [Tag: 15e71af]
```
Additionally, if you like Stranger Things, and to use a URL parameter with the tag, you can do
```
curl "https://hivemind.subcloudlabs.com/?name=Will"

Hello, The Upside Down (94.139.29.44)! I'm hivemind-deployment-7b7697f44-5wrkk [Tag: 15e71af]
```
- The ALB is created through the Kubernetes Ingress Object that is interacting with AWS ALB resources. It automatically resolves DNS upon recreation. I did this to remove future TLS and HTTP(s) connectivity overhead that is better handled with Terraform / AWS ACM. You can just focus on creating services without worrying about TLS now.
- You could expand this by additional authentication on the ALB Load Balancer. Doing so would stop unwanted requests from entering Kubernetes.
- You could expand this by adding WAF to the ALB for extra protection.
- Utilising AWS ALB here has the advantage of not having an already-prescribed ACM certificate with AWS. Less Kubernetes overhead.
How do you hit the endpoint? Example curl and expected output.
- What does the new URL parameter do? Example with and without it.
- How is HELLO_TAG set, and why is that value unique? (config, not hardcoded in the image)

## CI/CD Pipeline

This is currently trunk-based strategy. To deploy, either push or merge onto `main`.

- GitHub workflow is used as the main CI, currently on being used on the main branch.
- In team situations, you may want to have a workflow that lint, builds and tests on PRs before merging.
- On deployments for continuous integration, built images that pass scans are pushed to ECR.
- The app manifest for Kubernetes is updated by the Git workflow, which in turn is picked up by ArgoCD automatically.
- Improvement: You could add manual tagging for human intervention, to control deployments rather than relying on full automation. Just a suggestion. 
- Improvement: In team settings, `main` should not be pushed to, only PRs can merge into `main`. For this solution, a trunk-based works well though. I'm a one-man team right now ;)

## Security
- Kubernetes (EKS), Node Groups and other resources reside in private subnets. 
- The ALB is internet-facing, which resides in the public subnet.
- The bastion (EC2 instance) exists in a public subnet, and communicates through `AWS-StartPortForwardingSessionToRemoteHost`
- Secrets handling, TLS/certs (ACM), encryption at rest for state and cluster.
- Future improvements: Trivy should be utilised to do image scans, least privilege should also be used.
- Future improvements: proper secrets managements through AWS Secrets Manager / SSM Parameter Store should be used to store environment variables, and this source-of-truth should store where secrets reside.

## Cost Considerations
- NAT Gateways can be expensive especially with high loads of egress traffic. Just FYI.

## Tradeoffs & Limitations
- I simplified ArgoCD app-of-apps, as this was overkill, but in the case of having multiple apps in the same cluster, this would be very effective, especially with a team. 
- I simplified the GitOps strategy vis-a-vis the Git strategy, and opted for a trunk-based development environment.
- I ran short on time, and I would have loved to have used Fargate Profiles, as a neater way to manage nodes that do not rely on AMIs. 
- I wanted to utilise a base Ingress for the load balancer, and then separate the hivemind app into a different ArgoCD ApplicationSpec. In this way, it would make handling app specs easier, as you would just declare the routes and rules. But I traded this off by spending more time on getting AWS ALB to communicate with EKS through Ingress objects. I also spent more time making AWS ACM be compatible with Kubernetes.
- Since the configuration values within Helm Charts are not actually properly tracked by Terraform state, I would have utilised a better helm layout, but in order to deploy ArgoCD and the LB Controller, my trade-off was to use Terraform, as I ran short on time. 
- I would have opted for splitting up K8 objects better, and handling injections, either with more ArgoCD configuration, or Flux.
- And don't sweat the small stuff.

## What I'd Do in Production / Future Improvements
- Setup a dedicated `/healthz` HTTPRoute and change the health-check route to this. Use this route to check for successful connections to external resources, like RDS or Elasticache.
- One could roll out a Prometheus Sidecar to properly monitor time-series metrics and observability using Grafana.
- For green-blue, canary or more advanced deployments, one could use Argo Rollouts too. But as a starting point, ArgoCD suffices well as the application expands. Don't do too much too soon.
- You could utilise OPA and auto-apply certain infrastructure on terraform infrastructure.
- Multi-environments, probably namespaced or even on different EKS clusters. 
- If you have a high budget, an EKS cluster could even monitor other EKS clusters, which creates a high abstraction layer of up-time, especially if you want to observe other environments / services / infrastructure stacks.

## Cleanup
- To tear everything down, (`cd platform/infrastructure && terraform destroy`). This should take care of everything.
