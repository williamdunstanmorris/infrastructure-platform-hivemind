resource "github_repository" "infrastructure" {
  name       = "infrastructure-platform-hivemind"
  visibility = "public"
  auto_init  = true
}

resource "github_repository" "app" {
  name       = "hivemind-greeter"
  visibility = "public"
  auto_init  = true
}

resource "github_actions_variable" "ci" {
  for_each = {
    AWS_ROLE_ARN   = data.aws_iam_role.github_ci.arn
    AWS_REGION     = "eu-central-1"
    ECR_REPOSITORY = "main"
  }
  repository    = github_repository.app.name
  variable_name = each.key
  value         = each.value
}
