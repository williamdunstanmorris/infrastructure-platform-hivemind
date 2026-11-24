variable "argocd_admin_password" {
  type      = string
  sensitive = true
}

variable "argocd_admin_password_bcrypt" {
  type      = string
  sensitive = true
}

variable "kargo_admin_password_hash" {
  type      = string
  sensitive = true
}

variable "kargo_token_signing_key" {
  type      = string
  sensitive = true
}

variable "admin_allowed_cidrs" {
  type        = list(string)
  description = "e.g. [\"203.0.113.7/32\"] - your public IP"
}

variable "cratecli_repo_token" {
  type        = string
  sensitive   = true
  description = "Fine-grained PAT, CrateCLI only, Contents: read"
}
