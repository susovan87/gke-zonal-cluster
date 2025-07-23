# Minimal Outputs for GKE Zonal Cost-Optimized Learning Environment

# Basic project information
output "project_id" {
  description = "GCP project ID"
  value       = data.terraform_remote_state.bootstrap.outputs.project_id
}

output "region" {
  description = "GCP region"
  value       = data.terraform_remote_state.bootstrap.outputs.region
}

output "zone" {
  description = "GCP zone"
  value       = var.zone
}

# Cluster information
output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

# Network information
output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

# Node pool information
output "node_pool_name" {
  description = "Spot node pool name"
  value       = google_container_node_pool.spot_pool.name
}

output "node_count" {
  description = "Number of nodes in the spot pool"
  value       = var.node_count
}

# kubectl configuration command
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${data.terraform_remote_state.bootstrap.outputs.project_id}"
}
