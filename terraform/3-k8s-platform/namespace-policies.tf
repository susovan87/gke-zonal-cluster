# Namespace management and security baseline.
# Every namespace in var.namespaces automatically receives:
#   - Pod Security Standards labels (K8s 1.25+)
#   - Default LimitRanges for container resources
#   - Baseline Network Policies (deny-all + allow DNS + allow same-namespace)
#
# Component-specific network allow rules live in their respective files.


locals {
  namespaces_to_create = { for k, v in var.namespaces : k => v if v.create }

  # All namespaces that receive baseline network policies.
  # Merges user-defined workload namespaces with component namespaces.
  network_policy_namespaces = toset(concat(
    keys(var.namespaces),
    ["ingress-nginx"],
    var.enable_argocd ? ["argocd"] : [],
    var.enable_cloudflare_tunnel ? ["cloudflare"] : [],
  ))

  nginx_ingress_namespaces = toset([for k, v in var.namespaces : k if v.allow_nginx_ingress_8080])
}

# --- Namespace creation ---

resource "kubernetes_namespace" "managed" {
  for_each = local.namespaces_to_create

  metadata {
    name = each.key
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# --- Pod Security Standards labels ---

resource "kubernetes_labels" "pss" {
  for_each = var.namespaces

  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = each.key
  }

  labels = {
    "pod-security.kubernetes.io/enforce" = each.value.pss_enforce
    "pod-security.kubernetes.io/warn"    = each.value.pss_warn
    "pod-security.kubernetes.io/audit"   = each.value.pss_audit
  }

  depends_on = [kubernetes_namespace.managed]
}

# --- LimitRange defaults ---

resource "kubernetes_limit_range_v1" "defaults" {
  for_each = var.namespaces

  metadata {
    name      = "default-limits"
    namespace = each.key
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = each.value.limit_range.default_cpu
        memory = each.value.limit_range.default_memory
      }

      default_request = {
        cpu    = each.value.limit_range.request_cpu
        memory = each.value.limit_range.request_memory
      }

      max = {
        cpu    = each.value.limit_range.max_cpu
        memory = each.value.limit_range.max_memory
      }
    }
  }

  depends_on = [kubernetes_namespace.managed]
}

# --- Baseline Network Policies (Dataplane V2 / Cilium) ---
# Every namespace gets: deny-all ingress, deny-all egress, allow DNS, allow same-namespace.
# Component-specific allow rules are in their respective .tf files.

# Default deny all ingress traffic
resource "kubernetes_network_policy_v1" "default_deny_ingress" {
  for_each = local.network_policy_namespaces

  metadata {
    name      = "default-deny-ingress"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }

  depends_on = [
    kubernetes_namespace.managed,
    helm_release.nginx_ingress,
    helm_release.argocd,
    kubernetes_namespace.cloudflare,
  ]
}

# Default deny all egress traffic
resource "kubernetes_network_policy_v1" "default_deny_egress" {
  for_each = local.network_policy_namespaces

  metadata {
    name      = "default-deny-egress"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]
  }

  depends_on = [
    kubernetes_namespace.managed,
    helm_release.nginx_ingress,
    helm_release.argocd,
    kubernetes_namespace.cloudflare,
  ]
}

# Allow DNS resolution to kube-system (required when egress is denied)
resource "kubernetes_network_policy_v1" "allow_dns_egress" {
  for_each = local.network_policy_namespaces

  metadata {
    name      = "allow-dns-egress"
    namespace = each.key
  }

  spec {
    pod_selector {}

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }

      ports {
        port     = 53
        protocol = "UDP"
      }
      ports {
        port     = 53
        protocol = "TCP"
      }
    }

    policy_types = ["Egress"]
  }

  depends_on = [
    kubernetes_namespace.managed,
    helm_release.nginx_ingress,
    helm_release.argocd,
    kubernetes_namespace.cloudflare,
  ]
}

# Allow NGINX Ingress -> workloads on port 8080 (opt-in via allow_nginx_ingress_8080)
resource "kubernetes_network_policy_v1" "allow_from_ingress_nginx" {
  for_each = local.nginx_ingress_namespaces

  metadata {
    name      = "allow-from-ingress-nginx"
    namespace = each.key
  }

  spec {
    pod_selector {}

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

# Allow intra-namespace communication (pods within the same namespace)
resource "kubernetes_network_policy_v1" "allow_same_namespace" {
  for_each = local.network_policy_namespaces

  metadata {
    name      = "allow-same-namespace"
    namespace = each.key
  }

  spec {
    pod_selector {}

    ingress {
      from {
        pod_selector {}
      }
    }

    egress {
      to {
        pod_selector {}
      }
    }

    policy_types = ["Ingress", "Egress"]
  }

  depends_on = [
    kubernetes_namespace.managed,
    helm_release.nginx_ingress,
    helm_release.argocd,
    kubernetes_namespace.cloudflare,
  ]
}
