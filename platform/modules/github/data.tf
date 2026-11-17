data "aws_iam_role" "github_ci" { name = "main-github-ci" }

data "github_repository" "app" {
  name       = "CrateCLI"
}
