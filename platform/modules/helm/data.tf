data "aws_eks_cluster" "main" {
  name = "Main"
}

data "aws_iam_role" "lb_controller" {
  name = "${data.aws_eks_cluster.main.name}ALBEKSController"
}

data "aws_iam_role" "external_dns" {
  name = "${data.aws_eks_cluster.main.name}ExternalDNS"
}