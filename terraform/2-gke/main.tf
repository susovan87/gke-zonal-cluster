# Enable required Google Cloud APIs
resource "google_project_service" "container_api" {
  project = data.terraform_remote_state.bootstrap.outputs.project_id
  service = "container.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "compute_api" {
  project = data.terraform_remote_state.bootstrap.outputs.project_id
  service = "compute.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "iam_api" {
  project = data.terraform_remote_state.bootstrap.outputs.project_id
  service = "iam.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "binary_authorization_api" {
  project = data.terraform_remote_state.bootstrap.outputs.project_id
  service = "binaryauthorization.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Disable Network Intelligence Center to save ~€1.74/month
# Covers Network Analyzer; Topology and Performance Dashboard may require
# manual disablement in Cloud Console > Network Intelligence Center
resource "terraform_data" "disable_network_intelligence_center" {
  provisioner "local-exec" {
    command = "gcloud services disable networkmanagement.googleapis.com --project=${data.terraform_remote_state.bootstrap.outputs.project_id} --force"
  }
}

# Get access token for providers
data "google_client_config" "default" {}

# Data sources
data "google_project" "project" {
  project_id = data.terraform_remote_state.bootstrap.outputs.project_id
}
