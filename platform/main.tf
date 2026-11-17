module "helm" {
  source                       = "./modules/helm"
  argocd_admin_password        = var.argocd_admin_password
  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt
  kargo_admin_password_hash    = var.kargo_admin_password_hash
  kargo_token_signing_key      = var.kargo_token_signing_key
  admin_allowed_cidrs          = var.admin_allowed_cidrs
}

module "github" {
  source = "./modules/github"
}