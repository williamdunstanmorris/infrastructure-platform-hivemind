terraform {
  required_version = ">1.16.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0.0"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-435957166704-eu-central-1-an"
    key     = "infrastructure/tf-state.json"
    profile = "hivemind"
    region  = "eu-central-1"
  }
}
