resource "aws_ecr_repository" "default" {
  name                 = "main"
  image_tag_mutability = "IMMUTABLE" # ~ docker_config.immutable_tags = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}
