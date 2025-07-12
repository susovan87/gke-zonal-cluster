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
