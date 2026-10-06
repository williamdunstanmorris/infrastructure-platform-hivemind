data "aws_availability_zones" "available" {}

# data "aws_iam_policy_document" "bastion_assume" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }
