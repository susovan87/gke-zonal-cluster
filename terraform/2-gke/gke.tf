# NOTE: This cluster uses raw google_container_cluster / google_container_node_pool
# resources instead of the official terraform-google-modules/kubernetes-engine module.
# This is a deliberate choice for this learning environment:
#   - Full transparency: every setting is explicit, nothing hidden behind abstractions
#   - Simpler debugging: maps directly to the Google provider docs
#   - Minimal cluster: single zone, single node pool, no autoscaling — the module's
#     100+ variables target enterprise multi-pool setups and would be mostly unused
#   - Key security features (Workload Identity, Dataplane V2, private nodes, Shielded
#     Nodes, Binary Authorization, dedicated SA) are already configured manually
# For production/enterprise clusters, consider the official module's safer-cluster
# variant for CIS compliance and opinionated security defaults.

# Cost-optimized zonal cluster with spot nodes only
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  # Use stable release channel for predictable updates
  release_channel {
    channel = "REGULAR"
  }

  # Workload Identity Federation for per-pod GCP identity
  workload_identity_config {
    workload_pool = "${data.terraform_remote_state.bootstrap.outputs.project_id}.svc.id.goog"
  }

  # Ensure APIs are enabled before creating the cluster
  depends_on = [
    google_project_service.container_api,
    google_project_service.compute_api,
    google_project_service.iam_api,
    google_project_service.binary_authorization_api,
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

  # Enable Dataplane V2 for native NetworkPolicy enforcement (eBPF/Cilium)
  # NOTE: Changing this forces cluster recreation
  datapath_provider = "ADVANCED_DATAPATH"

  # Private cluster with PSC-based control plane (no VPC peering)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Keep public endpoint for kubectl access

    master_global_access_config {
      enabled = true
    }
  }

  # Binary Authorization - evaluation only (logs violations, doesn't block)
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
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

  vertical_pod_autoscaling {
    enabled = var.enable_vpa
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

# Binary Authorization policy - dry-run deny (logs all deployments, blocks nothing)
resource "google_binary_authorization_policy" "policy" {
  count   = var.enable_binary_authorization ? 1 : 0
  project = data.terraform_remote_state.bootstrap.outputs.project_id

  default_admission_rule {
    evaluation_mode  = "ALWAYS_DENY"
    enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"
  }

  depends_on = [google_project_service.binary_authorization_api]
}
