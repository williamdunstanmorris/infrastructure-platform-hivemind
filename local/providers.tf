provider "helm"       { kubernetes = local.k8s }
provider "kubernetes" {
  host                   = local.k8s.host
  client_certificate     = local.k8s.client_certificate
  client_key             = local.k8s.client_key
  cluster_ca_certificate = local.k8s.cluster_ca_certificate
}
