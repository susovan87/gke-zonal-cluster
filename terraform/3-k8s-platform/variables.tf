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

variable "nginx_ingress_replicas" {
  description = "Number of NGINX Ingress Controller replicas"
  type        = number
  default     = 2
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
