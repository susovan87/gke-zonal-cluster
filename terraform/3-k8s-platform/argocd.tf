# Argo CD - GitOps continuous delivery for Kubernetes
# Terraform owns the platform (Argo CD install), Argo CD owns the workloads

resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.4.10"
  namespace  = "argocd"

  create_namespace = true
  wait             = true
  timeout          = 300

  values = [
    templatefile("${path.module}/helm-values/argocd.yaml", {
      enable_argocd_ingress = var.enable_argocd_ingress
      argocd_hostname       = var.argocd_hostname
    })
  ]
}

# Allow ArgoCD internal communication (server, repo-server, controller, redis)
resource "kubernetes_network_policy_v1" "argocd_allow_internal" {
  count = var.enable_argocd ? 1 : 0

  metadata {
    name      = "allow-argocd-internal"
    namespace = "argocd"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/part-of" = "argocd"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "argocd"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/part-of" = "argocd"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }

  depends_on = [helm_release.argocd]
}

# Allow NGINX Ingress → ArgoCD server on port 8080
resource "kubernetes_network_policy_v1" "argocd_allow_from_ingress_nginx" {
  count = var.enable_argocd ? 1 : 0

  metadata {
    name      = "allow-from-ingress-nginx"
    namespace = "argocd"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "argocd-server"
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

  depends_on = [helm_release.argocd]
}

# Allow ArgoCD egress to external git repos, Kubernetes API, and app namespaces
resource "kubernetes_network_policy_v1" "argocd_allow_egress" {
  count = var.enable_argocd ? 1 : 0

  metadata {
    name      = "allow-argocd-egress"
    namespace = "argocd"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/part-of" = "argocd"
      }
    }

    # ArgoCD needs: external HTTPS (git repos), K8s API server, app namespaces
    egress {}

    policy_types = ["Egress"]
  }

  depends_on = [helm_release.argocd]
}
