resource "helm_release" "argo_cd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.15"
  create_namespace = true
  namespace        = "argocd"
  set_sensitive = [
    {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.argocd_admin_password_bcrypt
    }
  ]
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.14.0" # chart for controller v2.14.1, matches the IAM policy file in infra/
  namespace  = "kube-system"

  set = [
    { name = "clusterName", value = data.aws_eks_cluster.main.name },

    # Pass these explicitly: they can't always be discovered from the instance
    # metadata service when IMDS access is restricted.
    { name = "region", value = "eu-central-1" },
    { name = "vpcId", value = data.aws_eks_cluster.main.vpc_config[0].vpc_id },

    # The chart creates the service account and annotates it with the IAM role
    # (IRSA). This replaces eksctl create iamserviceaccount.
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn",
    value = data.aws_iam_role.lb_controller.arn },
  ]
}

