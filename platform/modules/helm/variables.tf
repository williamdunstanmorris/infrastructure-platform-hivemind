variable "argocd_admin_password" {
  type      = string
  sensitive = true
}

variable "argocd_admin_password_bcrypt" {
  type      = string
  sensitive = true
}