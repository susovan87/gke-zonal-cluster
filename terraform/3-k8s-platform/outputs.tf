# Outputs for Kubernetes Platform Components

# NGINX Ingress Controller information
output "nginx_ingress_status" {
  description = "NGINX Ingress Controller deployment status"
  value = {
    chart_version = helm_release.nginx_ingress.version
    namespace     = helm_release.nginx_ingress.namespace
    status        = helm_release.nginx_ingress.status
  }
}

# Cloudflare Tunnel information
output "cloudflare_tunnel_status" {
  description = "Cloudflare Tunnel deployment status"
  value = {
    enabled   = var.enable_cloudflare_tunnel
    namespace = var.enable_cloudflare_tunnel ? kubernetes_namespace.cloudflare[0].metadata[0].name : null
    note      = "Configure routes in Cloudflare Zero Trust Dashboard: https://one.dash.cloudflare.com/networks/tunnels"
  }
}

# Storage Classes information
output "storage_classes" {
  description = "Custom storage classes deployment status"
  value = {
    enabled        = var.enable_storage_classes
    cost_optimized = var.enable_storage_classes ? kubernetes_storage_class.cost_optimized[0].metadata[0].name : null
    fast           = var.enable_storage_classes ? kubernetes_storage_class.fast[0].metadata[0].name : null
  }
}

# Argo CD information
output "argocd_status" {
  description = "Argo CD deployment status"
  value = {
    enabled       = var.enable_argocd
    chart_version = var.enable_argocd ? helm_release.argocd[0].version : null
    namespace     = var.enable_argocd ? helm_release.argocd[0].namespace : null
    ui_access     = var.enable_argocd ? (var.enable_argocd_ingress ? "https://${var.argocd_hostname}" : "kubectl port-forward svc/argocd-server -n argocd 8080:80 → http://localhost:8080") : null
    get_password  = var.enable_argocd ? "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" : null
    hello_world_app = var.enable_argocd && var.enable_argocd_hello_world_app ? "enabled" : "disabled"
  }
}

# Cluster access information from previous stage
output "cluster_info" {
  description = "GKE cluster information from previous stage"
  value = {
    project_id   = data.terraform_remote_state.gke.outputs.project_id
    cluster_name = data.terraform_remote_state.gke.outputs.cluster_name
    region       = data.terraform_remote_state.gke.outputs.region
    zone         = data.terraform_remote_state.gke.outputs.zone
  }
}

# kubectl configuration command
output "kubectl_config_command" {
  description = "Command to configure kubectl for accessing the cluster"
  value       = data.terraform_remote_state.gke.outputs.kubectl_config_command
}
