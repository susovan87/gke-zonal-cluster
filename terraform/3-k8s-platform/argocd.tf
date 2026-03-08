# Argo CD - GitOps continuous delivery for Kubernetes
# Terraform owns the platform (Argo CD install), Argo CD owns the workloads

resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.13"
  namespace  = "argocd"

  create_namespace = true
  wait             = true
  timeout          = 300

  values = [
    yamlencode({
      # Global tolerations for ARM64 across all sub-components
      global = {
        tolerations = [
          {
            key      = "kubernetes.io/arch"
            operator = "Equal"
            value    = "arm64"
            effect   = "NoSchedule"
          }
        ]
      }

      # Disable non-essential components to save resources
      dex = {
        enabled = false
      }

      notifications = {
        enabled = false
      }

      applicationSet = {
        enabled = false
      }

      # Server component
      server = {
        extraArgs = ["--insecure"]

        resources = {
          requests = {
            cpu    = "50m"
            memory = "96Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }

        # Optional Ingress
        ingress = {
          enabled          = var.enable_argocd_ingress
          ingressClassName = "nginx"
          hostname         = var.argocd_hostname
          annotations = {
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
          }
          extraTls = var.enable_argocd_ingress ? [
            {
              hosts = [var.argocd_hostname]
            }
          ] : []
        }
      }

      # Repo Server component
      repoServer = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "96Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      # Application Controller
      controller = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "384Mi"
          }
        }
      }

      # Redis
      redis = {
        resources = {
          requests = {
            cpu    = "10m"
            memory = "32Mi"
          }
          limits = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
    })
  ]
}
