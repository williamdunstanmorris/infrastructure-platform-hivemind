provider "aws" {
  profile = "hivemind"
  default_tags {
    tags = {
      Owner = "Will Morris"
    }
  }
}

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
