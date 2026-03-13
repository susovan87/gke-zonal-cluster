# Minimal NGINX Ingress Controller optimized for ARM nodes and spot instances

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.15.0"
  namespace  = "ingress-nginx"

  create_namespace = true
  wait             = true
  timeout          = 300

  values = [
    templatefile("${path.module}/helm-values/nginx-ingress.yaml", {
      platform_replicas = var.platform_replicas
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

# --- Network Policies ---
# Baseline policies (deny-all, DNS, same-namespace) are in namespace-policies.tf.
# Only component-specific allow rules below.

# Allow Cloudflare Tunnel → NGINX Ingress Controller on ports 80/443
resource "kubernetes_network_policy_v1" "ingress_nginx_allow_from_cloudflare" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  metadata {
    name      = "allow-from-cloudflare-tunnel"
    namespace = "ingress-nginx"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/component" = "controller"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "app.kubernetes.io/name" = "cloudflare-tunnel"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "cloudflare-tunnel"
          }
        }
      }

      ports {
        port     = 80
        protocol = "TCP"
      }
      ports {
        port     = 443
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }

  depends_on = [helm_release.nginx_ingress]
}

# Allow NGINX Ingress Controller egress to backend pods in any namespace
# and to the Kubernetes API server (for Ingress resource watching)
resource "kubernetes_network_policy_v1" "ingress_nginx_allow_egress" {

  metadata {
    name      = "allow-controller-egress"
    namespace = "ingress-nginx"
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"      = "ingress-nginx"
        "app.kubernetes.io/component" = "controller"
      }
    }

    # Controller needs: API server (watch Ingress resources), backend pods (any namespace)
    egress {}

    policy_types = ["Egress"]
  }

  depends_on = [helm_release.nginx_ingress]
}
