module "helm" {
  source                       = "./modules/helm"
  argocd_admin_password        = var.argocd_admin_password
  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt
}

module "argo_cd" {
  source = "./modules/argo-cd"
  argocd_admin_password        = var.argocd_admin_password
  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt
}

module "eks_kubernetes_administration" {
  source = "./modules/eks-kubernetes-admin"
  # ArgoCD needs to have successfully created the ALB for Route53 to provide an ALIAS.
  depends_on = [
    module.argo_cd
  ]
}

module "github" {
  source = "./modules/github"
}