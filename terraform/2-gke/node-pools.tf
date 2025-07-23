# Single spot node pool for cost optimization
resource "google_container_node_pool" "spot_pool" {
  name       = "spot-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  # Spot node configuration for maximum cost savings
  node_config {
    # ARM-based machine type for better price/performance
    machine_type = "t2a-standard-2"

    # Spot instances for 60-91% cost savings
    spot = true

    # Use Container-Optimized OS with containerd
    image_type = "COS_CONTAINERD"

    # Minimal disk size to reduce costs
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"

    # Essential OAuth scopes only
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Node labels for workload scheduling
    labels = {
      node-pool = "spot"
      arch      = "arm64"
    }



    # Enable secure boot for basic security
    shielded_instance_config {
      enable_secure_boot = true
    }

    # Basic resource labels
    resource_labels = {
      node_pool   = "spot"
      environment = "learning"
    }
  }

  # Node management configuration
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings - conditional based on node count
  upgrade_settings {
    strategy = "SURGE"
    # Single node: recreate strategy (max_unavailable=1, max_surge=0)
    # Multi-node: rolling update (max_unavailable=0, max_surge=1)
    max_surge       = var.node_count == 1 ? 0 : 1
    max_unavailable = var.node_count == 1 ? 1 : 0
  }

}
