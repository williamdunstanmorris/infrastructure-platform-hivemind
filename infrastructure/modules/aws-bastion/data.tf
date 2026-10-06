data "aws_region" "current" {}

# Latest Amazon Linux 2023 AMI (SSM agent is preinstalled on it)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_iam_policy_document" "bastion_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["Main"]
  }
}

data "aws_eks_cluster" "main" {
  name = "Main"
}

# data "aws_security_group" "eks_cluster"{
#   filter {
#     name = "tag:Name"
#     values = ["eks-cluster-sg-Main*"]
#   }
# }

data "aws_subnets" "private_subnets_ids" {
  filter {
    name   = "tag:Name"
    values = ["Private*"]
  }
}
