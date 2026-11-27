variable "argocd_admin_password_bcrypt" {
  type      = string
  sensitive = true
}

variable "root_exclude" {
  type = string
  default = ""
}

variable "extra_argocd_cm" {
  type = map(string)
  default = {}
}