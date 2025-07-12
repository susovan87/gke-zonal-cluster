# Custom Storage Classes for GKE Zonal Cost-Optimized Environment

# Cost-optimized storage class (default for most workloads)
resource "kubernetes_storage_class" "cost_optimized" {
  count = var.enable_storage_classes ? 1 : 0

  metadata {
    name = "cost-optimized"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type                       = "pd-standard"
    replication-type           = "none"
    provisioned-iops-on-create = "false"
  }
}

# Fast storage class for databases and high-performance workloads
resource "kubernetes_storage_class" "fast" {
  count = var.enable_storage_classes ? 1 : 0

  metadata {
    name = "fast"
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type                       = "pd-ssd"
    replication-type           = "none"
    provisioned-iops-on-create = "false"
  }
}
