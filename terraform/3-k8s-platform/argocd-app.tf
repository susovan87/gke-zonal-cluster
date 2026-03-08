# Argo CD Applications - deployed via argocd-apps Helm chart
# Using Helm chart avoids CRD-at-plan-time issues with kubernetes_manifest

resource "helm_release" "argocd_hello_world" {
  count = var.enable_argocd && var.enable_argocd_hello_world_app ? 1 : 0

  name       = "argocd-hello-world"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.2"
  namespace  = "argocd"

  values = [
    yamlencode({
      applications = {
        hello-world = {
          namespace = "argocd"
          project   = "default"

          source = {
            repoURL        = "https://github.com/susovan87/gke-zonal-cluster.git"
            targetRevision  = "HEAD"
            path           = "k8s/hello-world-app/overlays/development"
          }

          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "hello-world-dev"
          }

          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true"
            ]
          }
        }
      }
    })
  ]

  depends_on = [helm_release.argocd]
}
