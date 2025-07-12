terraform {
  required_version = "~> 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.42"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  backend "gcs" {
    # Backend configuration is provided via backend.config file
    # Run: terraform init -backend-config=backend.config
  }
}

# Data sources to get cluster information from previous phase
data "terraform_remote_state" "bootstrap" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "1-bootstrap"
  }
}

# Configure providers
provider "google" {
  project = data.terraform_remote_state.bootstrap.outputs.project_id
  region  = data.terraform_remote_state.bootstrap.outputs.region
  zone    = var.zone
}
