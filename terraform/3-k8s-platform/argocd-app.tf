# Argo CD root Application (app-of-apps pattern)
# Terraform bootstraps a single root app that watches k8s/argocd-apps/.
# Child Applications are plain YAML in git — no terraform apply needed to
# add/remove apps or change targetRevision.

resource "helm_release" "argocd_root_app" {
  count = var.enable_argocd ? 1 : 0

  name       = "argocd-root-app"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.4"
  namespace  = "argocd"

  values = [templatefile("${path.module}/helm-values/argocd-root-app.yaml.tftpl", {
    repo_url = var.argocd_repo_url
  })]

  depends_on = [helm_release.argocd]
}
