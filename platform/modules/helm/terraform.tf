terraform {
  required_version = ">1.16.0"
  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
  }
}
