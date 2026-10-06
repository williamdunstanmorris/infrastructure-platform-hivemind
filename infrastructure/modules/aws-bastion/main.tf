resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.private_subnets_ids.ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  lifecycle {
    # Don't replace the instance whenever a newer AMI is published.
    ignore_changes = [ami]
  }
  tags = {
    Name = "bastion"
  }
}

resource "aws_security_group" "ssm_endpoints" {
  name        = "bastion-ssm-endpoints"
  description = "HTTPS from the bastion to SSM VPC endpoints"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "ssm_endpoints_from_bastion" {
  security_group_id            = aws_security_group.ssm_endpoints.id
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(["ssm", "ssmmessages", "ec2messages"])

  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.private_subnets_ids.ids
  security_group_ids  = [aws_security_group.ssm_endpoints.id]
  private_dns_enabled = true
}
