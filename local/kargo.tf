resource "kubernetes_secret_v1" "kargo_admin" {
  metadata {
    name      = "kargo-admin"
    namespace = "kargo"
  }
  data = {
    ADMIN_ACCOUNT_PASSWORD_HASH     = var.kargo_admin_password_hash
    ADMIN_ACCOUNT_TOKEN_SIGNING_KEY = var.kargo_token_signing_key
  }
}