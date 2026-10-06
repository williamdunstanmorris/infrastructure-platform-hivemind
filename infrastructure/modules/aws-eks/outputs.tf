output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "eks_api_host" {
  description = "Hostname for the SSM port-forward and kubeconfig tls-server-name"
  value       = replace(aws_eks_cluster.main.endpoint, "https://", "")
}
