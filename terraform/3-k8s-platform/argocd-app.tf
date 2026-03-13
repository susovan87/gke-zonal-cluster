# Argo CD Applications - deployed via argocd-apps Helm chart
# Using Helm chart avoids CRD-at-plan-time issues with kubernetes_manifest

resource "helm_release" "argocd_apps" {
  count = var.enable_argocd && length(var.argocd_hello_world_envs) > 0 ? 1 : 0

  name       = "argocd-hello-world"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.4"
  namespace  = "argocd"

  values = [templatefile("${path.module}/helm-values/argocd-apps.yaml.tftpl", {
    envs = var.argocd_hello_world_envs
  })]

  depends_on = [helm_release.argocd]
}

# Allow NGINX Ingress -> echo-app on port 8080 (per environment)
resource "kubernetes_network_policy_v1" "hello_world_allow_from_ingress_nginx" {
  for_each = var.enable_argocd ? var.argocd_hello_world_envs : {}

  metadata {
    name      = "allow-from-ingress-nginx"
    namespace = each.value.target_namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "echo-app"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name"      = "ingress-nginx"
            "app.kubernetes.io/component" = "controller"
          }
        }
      }

      ports {
        port     = 8080
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }

  depends_on = [kubernetes_namespace.managed]
}
