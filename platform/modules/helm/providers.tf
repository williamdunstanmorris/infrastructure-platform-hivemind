provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

provider "argocd" {
  username                    = "admin"
  password                    = var.argocd_admin_password
  port_forward_with_namespace = "argocd"
  insecure                    = true
}
