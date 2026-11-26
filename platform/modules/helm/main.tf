resource "helm_release" "argo_cd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.5.15"
  create_namespace = true
  namespace        = "argocd"

  values = [yamlencode({
    configs = {
      cm = {
        # Lets Argo CD judge whether a child Application is healthy.
        # Without this, sync waves don't wait for the previous wave to be ready.
        "resource.customizations.health.argoproj.io_Application" = <<-EOT
          hs = { status = "Progressing", message = "" }
          if obj.status ~= nil and obj.status.health ~= nil then
            hs.status = obj.status.health.status
            hs.message = obj.status.health.message or ""
          end
          return hs
        EOT
      }
    }
  })]

  set_sensitive = [
    { name = "configs.secret.argocdServerAdminPassword", value = var.argocd_admin_password_bcrypt },
    # Repo credential for the private CrateCLI repo: the chart renders it as a
    # Secret labelled argocd.argoproj.io/secret-type=repository.
    { name = "configs.repositories.cratecli.url", value = "https://github.com/williamdunstanmorris/CrateCLI" },
    { name = "configs.repositories.cratecli.type", value = "git" },
    { name = "configs.repositories.cratecli.username", value = "williamdunstanmorris" },
  ]
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.8"
  namespace  = "argocd"

  values = [yamlencode({
    applications = {
      root = {
        namespace   = "argocd"
        finalizers  = ["resources-finalizer.argocd.argoproj.io"]
        project     = "default"
        destination = { server = "https://kubernetes.default.svc", namespace = "argocd" }
        source = {
          repoURL        = "https://github.com/williamdunstanmorris/infrastructure-platform-hivemind"
          targetRevision = "HEAD"
          path           = "platform/gitops/1-root"
        }
        syncPolicy = { automated = { prune = true, selfHeal = true } }
      }
    }
  })]

  depends_on = [helm_release.argo_cd]
}