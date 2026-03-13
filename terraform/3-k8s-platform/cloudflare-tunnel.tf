# Cloudflare Tunnel Namespace
resource "kubernetes_namespace" "cloudflare" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  metadata {
    name = "cloudflare"
    labels = {
      "app.kubernetes.io/name"       = "cloudflare-tunnel"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Cloudflare Tunnel Token Secret
resource "kubernetes_secret" "cloudflare_tunnel_token" {
  count = var.enable_cloudflare_tunnel && var.cloudflare_tunnel_token != "" ? 1 : 0

  metadata {
    name      = "cloudflare-tunnel-token"
    namespace = kubernetes_namespace.cloudflare[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = "cloudflare-tunnel"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "Opaque"

  data = {
    token = var.cloudflare_tunnel_token
  }
}

# Cloudflare Tunnel Deployment
resource "kubernetes_deployment" "cloudflare_tunnel" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  metadata {
    name      = "cloudflare-tunnel"
    namespace = kubernetes_namespace.cloudflare[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = "cloudflare-tunnel"
      "app.kubernetes.io/version"    = "latest"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = var.platform_replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "cloudflare-tunnel"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "cloudflare-tunnel"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8080"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        # Topology spread constraints - distribute pods evenly across nodes (conditional)
        dynamic "topology_spread_constraint" {
          for_each = var.platform_replicas > 1 ? [1] : []
          content {
            max_skew           = 1
            topology_key       = "kubernetes.io/hostname"
            when_unsatisfiable = "ScheduleAnyway"
            label_selector {
              match_labels = {
                "app.kubernetes.io/name" = "cloudflare-tunnel"
              }
            }
          }
        }

        toleration {
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }

        # Security context with additional sysctls for ICMP (ping/traceroute)
        security_context {
          run_as_non_root = true
          run_as_user     = 65532 # nonroot user
          fs_group        = 65532

          # Allow ICMP traffic (ping, traceroute) - official recommendation
          sysctl {
            name  = "net.ipv4.ping_group_range"
            value = "65532 65532"
          }
        }

        container {
          name  = "cloudflare-tunnel"
          image = "cloudflare/cloudflared:latest"

          # Command and arguments for remotely-managed tunnel
          command = ["cloudflared"]
          args = [
            "tunnel",
            "--no-autoupdate",
            "--loglevel",
            "error",
            "--metrics",
            "0.0.0.0:8080",
            "run",
            "--token",
            "$(TUNNEL_TOKEN)"
          ]

          # Environment variables
          env {
            name = "TUNNEL_TOKEN"
            value_from {
              secret_key_ref {
                name = var.cloudflare_tunnel_token != "" ? kubernetes_secret.cloudflare_tunnel_token[0].metadata[0].name : "cloudflare-tunnel-token"
                key  = "token"
              }
            }
          }

          env {
            name  = "TUNNEL_METRICS"
            value = "0.0.0.0:8080"
          }

          env {
            name  = "TUNNEL_LOGFILE"
            value = "/dev/stdout"
          }

          # Resource limits for cost optimization
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          # Health checks - use /ready endpoint as per official guide
          liveness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 1
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 1
          }

          port {
            name           = "metrics"
            container_port = 8080
            protocol       = "TCP"
          }

          # Security context for container
          security_context {
            run_as_non_root            = true
            run_as_user                = 65532
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        # Pod disruption budget settings
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30

        # DNS policy for better connectivity
        dns_policy = "ClusterFirst"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
        max_surge       = "1"
      }
    }
  }

  depends_on = [
    helm_release.nginx_ingress,
    kubernetes_secret.cloudflare_tunnel_token
  ]
}

# Cloudflare Tunnel Service (for metrics)
resource "kubernetes_service" "cloudflare_tunnel_metrics" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  metadata {
    name      = "cloudflare-tunnel-metrics"
    namespace = kubernetes_namespace.cloudflare[0].metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = "cloudflare-tunnel"
      "app.kubernetes.io/managed-by" = "terraform"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "8080"
      "prometheus.io/path"   = "/metrics"
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "cloudflare-tunnel"
    }

    port {
      name        = "metrics"
      port        = 8080
      target_port = "metrics"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Pod Disruption Budget for Cloudflare Tunnel (only for multi-replica setups)
resource "kubernetes_pod_disruption_budget_v1" "cloudflare_tunnel" {
  count = var.enable_cloudflare_tunnel && var.platform_replicas > 1 ? 1 : 0

  metadata {
    name      = "cloudflare-tunnel-pdb"
    namespace = kubernetes_namespace.cloudflare[0].metadata[0].name
  }

  spec {
    min_available = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "cloudflare-tunnel"
      }
    }
  }
}


# Allow metrics scraping on port 8080
resource "kubernetes_network_policy_v1" "cloudflare_allow_metrics" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  metadata {
    name      = "allow-metrics"
    namespace = kubernetes_namespace.cloudflare[0].metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "cloudflare-tunnel"
      }
    }

    ingress {
      ports {
        port     = 8080
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}

# Allow Cloudflare Tunnel egress to Cloudflare edge and NGINX Ingress
resource "kubernetes_network_policy_v1" "cloudflare_allow_egress" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  metadata {
    name      = "allow-tunnel-egress"
    namespace = kubernetes_namespace.cloudflare[0].metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "cloudflare-tunnel"
      }
    }

    # Tunnel needs: Cloudflare edge (external HTTPS), NGINX Ingress (forward traffic)
    egress {}

    policy_types = ["Egress"]
  }
}
