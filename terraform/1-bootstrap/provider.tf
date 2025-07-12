terraform {
  required_version = "~> 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.42"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.6"
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
