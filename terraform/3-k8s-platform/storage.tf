# Custom Storage Classes for GKE Zonal Cost-Optimized Environment
#
# GKE's built-in "standard-rwo" (pd-standard, WaitForFirstConsumer) is kept as
# the default. On a zonal cluster it already provides cost-optimized single-zone
# PDs, so no custom default is needed.

# Fast storage class for databases and high-performance workloads
resource "kubernetes_storage_class" "fast" {
  metadata {
    name = "fast"
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type             = "pd-ssd"
    replication-type = "none"
  }
}
