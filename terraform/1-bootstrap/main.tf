# Bootstrap Terraform State Storage and Lock Configuration, Enables necessary APIs

# Random suffix for bucket name to ensure global uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Enable required APIs
resource "google_project_service" "storage_api" {
  project = var.project_id
  service = "storage.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "cloudresourcemanager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create GCS bucket for Terraform state
resource "google_storage_bucket" "terraform_state" {
  name          = "terraform-state-${var.project_id}-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = false

  # Enable versioning for state file history
  versioning {
    enabled = true
  }

  # Lifecycle management to reduce costs
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  # Security settings
  uniform_bucket_level_access = true

  depends_on = [google_project_service.storage_api]
}

# Block public access to the bucket
resource "google_storage_bucket_iam_binding" "terraform_state" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.admin"

  members = [
    "projectEditor:${var.project_id}",
    "projectOwner:${var.project_id}",
  ]
}
