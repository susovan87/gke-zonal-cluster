# Minimal Variables for GKE Zonal Cost-Optimized Learning Environment
variable "zone" {
  description = "The GCP zone for the zonal cluster"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "learning-cluster"
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-learning-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "gke-learning-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pods_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "master_ipv4_cidr" {
  description = "CIDR range for the master network"
  type        = string
  default     = "172.16.0.0/28"
}

variable "node_count" {
  description = "Number of spot nodes in the cluster"
  type        = number
  default     = 2
}

variable "disk_size_gb" {
  description = "Size of the node boot disk in GB"
  type        = number
  default     = 30
}

variable "tf_state_bucket" {
  description = "GCS bucket for Terraform state"
  type        = string
}
