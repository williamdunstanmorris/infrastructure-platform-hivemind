variable "argocd_admin_password_bcrypt" {
  type      = string
  sensitive = true
}

variable "cratecli_repo_token" {
  type        = string
  sensitive   = true
  description = "Fine-grained PAT, CrateCLI only, Contents: read"
}