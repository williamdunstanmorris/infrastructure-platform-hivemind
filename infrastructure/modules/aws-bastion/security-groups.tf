resource "aws_security_group" "bastion" {
  name        = "bastion-access"
  description = "SSM bastion, no inbound, HTTPS egress within the VPC only"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_vpc_security_group_egress_rule" "bastion_https_vpc" {
  security_group_id = aws_security_group.bastion.id
  description       = "Outbound HTTPS to SSM endpoints and EKS API inside the VPC"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "bastion_to_eks_api" {
  security_group_id            = data.aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description                  = "Inbound Bastion tunnel to EKS API"
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}