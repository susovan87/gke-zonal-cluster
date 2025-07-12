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

# Get access token for providers
data "google_client_config" "default" {}

# Data sources
data "google_project" "project" {
  project_id = data.terraform_remote_state.bootstrap.outputs.project_id
}
