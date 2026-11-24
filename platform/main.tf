module "helm" {
  source                       = "./modules/helm"
  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt
  cratecli_repo_token = var.cratecli_repo_token
}

module "github" {
  source = "./modules/github"
}