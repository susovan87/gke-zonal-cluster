# Minimal NGINX Ingress Controller optimized for ARM nodes and spot instances

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace  = "ingress-nginx"

  create_namespace = true
  wait             = true
  timeout          = 300

  values = [
    yamlencode({
      controller = {
        # Minimal resource requests for cost optimization
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }

        # Configure replica count from variable
        replicaCount = var.nginx_ingress_replicas

        # Topology spread constraints for high availability
        topologySpreadConstraints = [
          {
            maxSkew           = 1
            topologyKey       = "kubernetes.io/hostname"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"      = "ingress-nginx"
                "app.kubernetes.io/instance"  = "nginx-ingress"
                "app.kubernetes.io/component" = "controller"
              }
            }
          }
        ]

        # Use ClusterIP service (Cloudflare Tunnel handles external access)
        service = {
          type = "ClusterIP"
        }

        # Tolerate ARM architecture
        tolerations = [
          {
            key      = "kubernetes.io/arch"
            operator = "Equal"
            value    = "arm64"
            effect   = "NoSchedule"
          }
        ]

        # Disable admission webhooks for simplicity
        admissionWebhooks = {
          enabled = false
        }

        # Basic configuration optimizations
        config = {
          # Reduce connection limits for cost savings
          "worker-processes"       = "1"
          "worker-connections"     = "1024"
          "max-worker-connections" = "1024"

          # Optimize for ARM architecture
          "enable-real-ip" = "true"

          # Basic security headers
          "add-headers" = "ingress-nginx/custom-headers"
        }
      }

      # Minimal default backend
      defaultBackend = {
        enabled = true
        image = {
          repository = "registry.k8s.io/defaultbackend-arm64"
          tag        = "1.5"
        }
        resources = {
          requests = {
            cpu    = "10m"
            memory = "20Mi"
          }
          limits = {
            cpu    = "50m"
            memory = "64Mi"
          }
        }
        # Add ARM64 toleration for default backend
        tolerations = [
          {
            key      = "kubernetes.io/arch"
            operator = "Equal"
            value    = "arm64"
            effect   = "NoSchedule"
          }
        ]
        # Use default security context
      }
    })
  ]
}

# Custom headers ConfigMap for basic security
resource "kubernetes_config_map" "custom_headers" {
  metadata {
    name      = "custom-headers"
    namespace = "ingress-nginx"
  }

  data = {
    "X-Frame-Options"        = "DENY"
    "X-Content-Type-Options" = "nosniff"
    "X-XSS-Protection"       = "1; mode=block"
    "Referrer-Policy"        = "strict-origin-when-cross-origin"
  }

  depends_on = [helm_release.nginx_ingress]
}
