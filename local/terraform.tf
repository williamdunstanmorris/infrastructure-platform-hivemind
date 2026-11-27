terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind",
      version = "~> 0.9"
    }
    helm = {
      source = "hashicorp/helm",
      version = "3.2.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes",
      version = "~> 2.38"
    }
  }
}