variable "argocd_admin_password" {
  type      = string
  sensitive = true
}

variable "argocd_admin_password_bcrypt" {
  type      = string
  sensitive = true
}

variable "kargo_admin_password_hash" {
  type        = string
  sensitive   = true
  description = "bcrypt hash: htpasswd -bnBC 10 \"\" '<password>' | tr -d ':\\n'"
}

variable "kargo_token_signing_key" {
  type        = string
  sensitive   = true
  description = "openssl rand -base64 29 | tr -d \"=+/\" | cut -c1-32"
}

variable "admin_allowed_cidrs" {
  type        = list(string)
  description = "Source CIDRs allowed to reach the Argo CD and Kargo UIs through the shared ALB"
}
