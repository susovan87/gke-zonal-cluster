# Custom VPC network with subnet for the GKE cluster
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC network for GKE cluster"

  # Ensure Compute API is enabled
  depends_on = [google_project_service.compute_api]
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = data.terraform_remote_state.bootstrap.outputs.region
  network       = google_compute_network.vpc.id
  description   = "Subnet for GKE cluster nodes"

  # Secondary IP ranges for pods and services (VPC-native cluster)
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = var.services_cidr
  }

  # Enable private Google access for nodes without external IPs
  private_ip_google_access = true

  # Enable flow logs for network monitoring (disabled to optimize costs)
  # log_config {
  #   aggregation_interval = "INTERVAL_10_MIN"
  #   flow_sampling        = 0.5
  #   metadata             = "INCLUDE_ALL_METADATA"
  # }
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = data.terraform_remote_state.bootstrap.outputs.region
  network = google_compute_network.vpc.id

  description = "Router for Cloud NAT to provide internet access to private GKE nodes"
}

# Cloud NAT for outbound internet access from private nodes
resource "google_compute_router_nat" "nat" {
  name   = "${var.cluster_name}-nat"
  router = google_compute_router.router.name
  region = data.terraform_remote_state.bootstrap.outputs.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  # Optimize for cost - use minimum ports per VM
  min_ports_per_vm = 64

  # Enable endpoint independent mapping for better performance
  enable_endpoint_independent_mapping = false
}

# Firewall rule to allow internal communication within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, var.pods_cidr, var.services_cidr]
  description   = "Allow internal communication within the VPC"
}

# Firewall rule for health checks
resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.network_name}-allow-health-check"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["gke-node"]
  description   = "Allow Google Cloud health checks"
}

# Firewall rule for SSH access (optional, for debugging)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # Google IAP range for secure SSH
  target_tags   = ["gke-node"]
  description   = "Allow SSH via Google IAP"
}
