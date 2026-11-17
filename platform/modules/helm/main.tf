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

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.23.0" # app v0.23.0
  namespace  = "kube-system"

  values = [yamlencode({
    provider      = { name = "aws" }
    env           = [{ name = "AWS_DEFAULT_REGION", value = local.region }]
    domainFilters = [local.domain]
    sources       = ["ingress"]
    policy        = "sync" # deletes its records when an Ingress goes away: clean teardown
    txtOwnerId    = data.aws_eks_cluster.main.name
    serviceAccount = {
      name        = "external-dns" # must match the role's trust policy `sub`
      annotations = { "eks.amazonaws.com/role-arn" = data.aws_iam_role.external_dns.arn }
    }
  })]
}

# ── cert-manager ── required by Kargo for its self-signed webhook certs
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.21.3"
  namespace        = "cert-manager"
  create_namespace = true

  values = [yamlencode({
    crds = { enabled = true }
  })]
}

resource "helm_release" "kargo" {
  name             = "kargo"
  repository       = "oci://ghcr.io/akuity/kargo-charts"
  chart            = "kargo"
  version          = "1.12.5"
  namespace        = "kargo"
  create_namespace = true

  values = [yamlencode({
    api = {
      host = "kargo.${local.domain}"
      # ALB terminates TLS; API serves plain HTTP on service port 80.
      tls = { enabled = false, terminatedUpstream = true }
      ingress = {
        enabled          = true
        ingressClassName = "alb"
        pathType         = "Prefix"            # AWS LB controller doesn't support ImplementationSpecific "/"
        tls              = { enabled = false } # cert lives in ACM, not a k8s Secret
        annotations = merge(local.shared_alb_annotations, {
          "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz"
          "alb.ingress.kubernetes.io/conditions.kargo-api" = local.admin_only
        })
      }
    }
  })]

