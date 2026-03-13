terraform {
  required_version = "~> 1.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.22"
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

# Configure Google provider
provider "google" {
  project = var.project_id
  region  = var.region
}
