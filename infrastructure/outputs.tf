output "bastion_instance_id" {
  value = module.bastion.bastion_instance_id
}

output "eks_api_host" {
  description = "Hostname for the SSM port-forward and kubeconfig tls-server-name"
  value       = module.app_cluster.eks_api_host
}

output "certificate_arn" {
  description = "Certificate ARN"
  value       = module.dns.certificate_arn
}
