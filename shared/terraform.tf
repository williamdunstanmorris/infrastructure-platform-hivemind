terraform {
  required_version = ">1.16.0"
  required_providers {
    aws = {
      source = "hashicorp/aws",
      version = ">=5.0.0"
    }
  }
  backend "s3" {
    bucket       = "terraform-479592483600-eu-central-1-an"
    key          = "shared/tf-state.json"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}