locals {
  oidc_host = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

resource "aws_iam_role" "eks_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_default" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}


data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",          # join the cluster
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",               # VPC CNI manages ENIs/IPs
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly", # ~ devstorage.read_only: pull images from ECR
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",       # shell via SSM, so no SSH or bastion needed in private subnets
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",        # ~ logging.write / monitoring scopes
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_iam_openid_connect_provider" "eks" {
  url            = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}

# The controller's permissions (ALB/NLB, target groups, security groups, ...)
# Pinned to the same release as the Helm chart version in platform/.
resource "aws_iam_policy" "lb_controller" {
  name   = "${aws_eks_cluster.main.name}-lb-controller"
  policy = file("${path.module}/lb-controller-iam-policy.json")
}

resource "aws_iam_role" "lb_controller" {
  name               = "${aws_eks_cluster.main.name}ALBEKSController"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume.json
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

output "lb_controller_role_arn" {
  value = aws_iam_role.lb_controller.arn
}

