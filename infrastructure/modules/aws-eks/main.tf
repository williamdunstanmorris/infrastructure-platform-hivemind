resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn
  version  = var.cluster_version



  vpc_config {
    subnet_ids = data.aws_subnets.private_subnets_ids.ids
    # Reach the API via the VPC. Always on. Access API via SSMSessionManager.
    endpoint_private_access = true
    # The load balancer is the public point here.
    endpoint_public_access = false
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
  }

  # Audit trail. api + audit + authenticator are the useful ones.
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Modern auth: IAM principals mapped via EKS Access Entries (API), not the old aws-auth ConfigMap.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true # whoever runs apply gets admin; add access entries for CI
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_default,
    aws_cloudwatch_log_group.eks,
  ]
}

resource "aws_eks_node_group" "workload" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "app"
  node_role_arn   = aws_iam_role.node.arn

  # Private subnets across 3 AZs: the ASG behind the node group balances nodes
  # across them. GKE: you used a single zone via `location`.
  subnet_ids = data.aws_subnets.private_subnets_ids.ids

  instance_types = var.node_instance_types

  # GKE: autoscaling { min/max } + initial_node_count.
  # NOTE: this only sets ASG bounds. Something must actually scale it:
  # Cluster Autoscaler or Karpenter (installed separately, with IRSA).
  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }

  # GKE: upgrade_settings max_surge. EKS replaces nodes with surge too. Controls how many
  # nodes drain at once during AMI/version rollouts. PDBs are respected.
  update_config {
    max_unavailable = 1
  }

  #
  # labels = {
  #   "node-role" = "workload"
  # }

  # Same idea as your commented GKE taint. Uncomment for a dedicated system pool:
  # taint {
  #   key    = "node-role"
  #   value  = "system"
  #   effect = "NO_SCHEDULE"
  # }
}

