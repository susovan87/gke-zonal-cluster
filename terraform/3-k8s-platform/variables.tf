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

variable "enable_argocd" {
  description = "Enable Argo CD deployment"
  type        = bool
  default     = false
}

variable "enable_argocd_ingress" {
  description = "Enable Ingress for Argo CD server (default: use port-forward)"
  type        = bool
  default     = false
}

variable "argocd_hostname" {
  description = "Hostname for Argo CD Ingress"
  type        = string
  default     = "argocd.leisuretreasures.com"
}

variable "argocd_hello_world_envs" {
  description = "Map of hello-world-app environments to deploy via Argo CD"
  type = map(object({
    overlay_path     = string
    target_namespace = string
    target_revision  = optional(string, "HEAD")
  }))
  default = {}
}

variable "namespaces" {
  description = "Managed namespaces with security baseline (PSS labels, LimitRanges, Network Policies). Use create=false for pre-existing namespaces (e.g. default)."
  type = map(object({
    create      = optional(bool, true)
    pss_enforce = optional(string, "baseline")
    pss_warn    = optional(string, "restricted")
    pss_audit   = optional(string, "restricted")
    limit_range = optional(object({
      default_cpu    = optional(string, "500m")
      default_memory = optional(string, "256Mi")
      request_cpu    = optional(string, "50m")
      request_memory = optional(string, "64Mi")
      max_cpu        = optional(string, "1")
      max_memory     = optional(string, "512Mi")
    }), {})
  }))
  default = {}
}

variable "tf_state_bucket" {
  description = "GCS bucket for Terraform state"
  type        = string
}
