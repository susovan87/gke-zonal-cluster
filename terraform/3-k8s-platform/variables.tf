# Variables for Kubernetes Platform Components

variable "enable_cloudflare_tunnel" {
  description = "Enable Cloudflare Tunnel deployment"
  type        = bool
  default     = false
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token for remotely-managed tunnel authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "platform_replicas" {
  description = "Number of replicas for platform components (NGINX Ingress, Cloudflare Tunnel)"
  type        = number
  default     = 2
  validation {
    condition     = contains([1, 2], var.platform_replicas)
    error_message = "Platform replicas must be 1 (single-node) or 2 (HA mode)."
  }
}

variable "enable_storage_classes" {
  description = "Enable custom storage classes"
  type        = bool
  default     = true
}

variable "tf_state_bucket" {
  description = "GCS bucket for Terraform state"
  type        = string
}
