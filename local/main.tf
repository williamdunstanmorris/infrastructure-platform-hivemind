locals {
  k8s = {
    host                   = kind_cluster.this.endpoint
    client_certificate     = kind_cluster.this.client_certificate
    client_key             = kind_cluster.this.client_key
    cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
  }
}

resource "kind_cluster" "this" {
  name = "playground"
  wait_for_ready = true
  kubeconfig_path = "${path.module}/.kubeconfig"
}

module "helm" {
  source                       = "../platform/modules/helm"
  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt
  root_exclude = "platform-aws.yaml"
  extra_argocd_cm = {
    # No ingress controller locally → Ingresses never get an address → Argo CD
    # calls them Progressing forever → Kargo promotions hang. Locally, call them healthy.
    "resource.customizations.health.networking.k8s.io_Ingress" = "return { status = \"Healthy\" }"
  }
}
