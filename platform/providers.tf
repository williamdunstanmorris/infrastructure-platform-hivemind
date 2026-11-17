provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Owner = "William Morris"
    }
  }
}

# Explicit repo-local kubeconfig (written by connect.sh), never ~/.kube/config.
provider "helm" {
  kubernetes = {
    config_path = "${path.module}/.kubeconfig"
  }
}

provider "argocd" {
  username                    = "admin"
  password                    = var.argocd_admin_password
  port_forward_with_namespace = "argocd"
  insecure                    = true
}
