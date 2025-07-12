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
  }

  backend "gcs" {
    # Backend configuration is provided via backend.config file
    # Run: terraform init -backend-config=backend.config
  }
}

# Data sources to get cluster information from previous phase
data "terraform_remote_state" "gke" {
  backend = "gcs"
  config = {
    bucket = var.tf_state_bucket
    prefix = "2-gke"
  }
}

data "google_client_config" "default" {}

# Configure providers
provider "google" {
  project = data.terraform_remote_state.gke.outputs.project_id
  region  = data.terraform_remote_state.gke.outputs.region
  zone    = data.terraform_remote_state.gke.outputs.zone
}

provider "kubernetes" {
  host                   = "https://${data.terraform_remote_state.gke.outputs.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = "https://${data.terraform_remote_state.gke.outputs.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.cluster_ca_certificate)
  }
}
