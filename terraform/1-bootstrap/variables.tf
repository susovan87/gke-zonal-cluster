# Variables for Bootstrap Configuration

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"

  validation {
    condition = contains([
      "us-central1",
      "us-west1",
      "us-east1"
    ], var.region)
    error_message = "Region must be us-central1, us-west1, or us-east1 for free tier eligibility."
  }
}
