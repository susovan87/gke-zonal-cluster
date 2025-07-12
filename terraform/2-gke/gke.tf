# Cost-optimized zonal cluster with spot nodes only
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  # Use stable release channel for predictable updates
  release_channel {
    channel = "REGULAR"
  }

  # Ensure APIs are enabled before creating the cluster
  depends_on = [
    google_project_service.container_api,
    google_project_service.compute_api
  ]

  # Use the custom VPC network
  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  # Remove default node pool (we'll create a custom spot pool)
  remove_default_node_pool = true
  initial_node_count       = 1

  # Master authentication configuration
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # VPC-native cluster configuration
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"
    services_secondary_range_name = "services-range"
  }

  # Private cluster configuration for enhanced security
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Keep public endpoint for kubectl access
    master_ipv4_cidr_block  = var.master_ipv4_cidr

    master_global_access_config {
      enabled = true
    }
  }

  # Minimal addons configuration
  addons_config {
    # Disable HTTP Load Balancing (we use Cloudflare Tunnel)
    http_load_balancing {
      disabled = true
    }

    # Enable HPA for basic scaling
    horizontal_pod_autoscaling {
      disabled = false
    }

    # Enable DNS cache for better performance
    dns_cache_config {
      enabled = true
    }

    # Enable CSI driver for persistent volumes
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Disable cluster autoscaling (we manage nodes manually for cost control)
  cluster_autoscaling {
    enabled = false
  }

  # Maintenance window - 4 hours daily in off-peak hours
  maintenance_policy {
    recurring_window {
      start_time = "2025-06-28T01:00:00Z"
      end_time   = "2025-06-28T05:00:00Z"
      recurrence = "FREQ=DAILY"
    }
  }

  # Basic logging - system components only
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  # Basic monitoring - system components only
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  # Basic resource labels
  resource_labels = {
    environment = "learning"
    managed_by  = "terraform"
  }

  # Protect cluster from accidental deletion
  deletion_protection = false

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}
