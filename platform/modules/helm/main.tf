locals {
  region = "eu-central-1"
  domain = "subcloudlabs.com"

  # Every Ingress joining the shared ALB must agree on these (they are ALB-wide settings).
  # TLS: the ACM wildcard cert is auto-discovered from each Ingress host, so no certificate-arn here.
  shared_alb_annotations = {
    "alb.ingress.kubernetes.io/group.name"         = "shared"
    "alb.ingress.kubernetes.io/load-balancer-name" = "shared-alb"
    "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"        = "ip"
    "alb.ingress.kubernetes.io/listen-ports"       = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
    "alb.ingress.kubernetes.io/ssl-redirect"       = "443"
  }

  # Listener-rule condition restricting a backend service to admin IPs.
  # Per-rule, unlike inbound-cidrs, which would lock down the whole shared ALB.
  admin_only = jsonencode([{
    field          = "source-ip"
    sourceIpConfig = { values = var.admin_allowed_cidrs }
  }])
}

resource "helm_release" "argo_cd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.15"
  create_namespace = true
  namespace        = "argocd"

  values = [yamlencode({
    global = { domain = "argo.${local.domain}" }

    # ALB terminates TLS; argocd-server serves plain HTTP behind it.
    configs = { params = { "server.insecure" = true } }

    server = {
      ingress = {
        enabled          = true
        controller       = "aws" # chart adds a gRPC service + rule so the argocd CLI works through the ALB
        ingressClassName = "alb"
        aws              = { serviceType = "ClusterIP" } # target-type ip needs no NodePort
        annotations = merge(local.shared_alb_annotations, {
          "alb.ingress.kubernetes.io/healthcheck-path"         = "/healthz"
          "alb.ingress.kubernetes.io/conditions.argocd-server" = local.admin_only
          # The gRPC rule (argocd-server-grpc) carries the chart's own Content-Type condition
          # and cannot take a second one; it stays reachable but still requires Argo CD auth.
        })
      }
    }
  })]

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

