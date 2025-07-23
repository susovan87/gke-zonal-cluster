# Local values for common tags and configurations
locals {
  common_labels = {
    "environment"       = "learning"
    "managed-by"        = "terraform"
    "cost-optimization" = "enabled"
    "terraform-module"  = "3-k8s-platform"
  }

}
