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

    # Extra Kubernetes objects the chart installs alongside Argo CD.
    # This is the root Application: it points Argo CD at platform/gitops/root in git,
    # and from there Argo CD installs everything else.
    extraObjects = [{
      apiVersion = "argoproj.io/v1alpha1"
      kind       = "Application"
      metadata = {
        name       = "root"
        namespace  = "argocd"
        finalizers = ["resources-finalizer.argocd.argoproj.io"]
      }
      spec = {
        project     = "default"
        destination = { server = "https://kubernetes.default.svc", namespace = "argocd" }
        source = {
          repoURL        = "https://github.com/williamdunstanmorris/infrastructure-platform-hivemind"
          targetRevision = "HEAD"
          path           = "platform/gitops/root"
        }
        syncPolicy = { automated = { prune = true, selfHeal = true } }
      }
    }]
  })]

  set_sensitive = [
    { name = "configs.secret.argocdServerAdminPassword", value = var.argocd_admin_password_bcrypt },
  ]
}