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
