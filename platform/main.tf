module "helm" {
  source                       = "./modules/helm"
  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt
}

module "github" {
  source = "./modules/github"
}