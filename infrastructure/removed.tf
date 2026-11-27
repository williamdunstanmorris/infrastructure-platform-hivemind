removed {
  from = module.ecr
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_iam_openid_connect_provider.github
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_iam_role.github_ci
}

removed {
  from = aws_iam_role_policy.github_ci
}