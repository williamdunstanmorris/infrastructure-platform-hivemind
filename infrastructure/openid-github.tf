resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a21d290d981795861848425508034a040710",
    "06d927fecd0a84aeba28aad1d808139470fe95c3",
  ]
}

data "aws_iam_policy_document" "github_ci_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Matches ANY repository under your GitHub username/org
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:williamdunstanmorris/*"]
    }
  }
}

resource "aws_iam_role" "github_ci" {
  name               = "main-github-ci"
  assume_role_policy = data.aws_iam_policy_document.github_ci_assume.json
}

data "aws_iam_policy_document" "github_ci" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = [module.ecr.aws_ecr_repository_arn]
  }
}

resource "aws_iam_role_policy" "github_ci" {
  role   = aws_iam_role.github_ci.id
  policy = data.aws_iam_policy_document.github_ci.json
}