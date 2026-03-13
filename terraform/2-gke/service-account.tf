# Dedicated service account for GKE nodes with least-privilege IAM roles
resource "google_service_account" "gke_nodes" {
  project      = data.terraform_remote_state.bootstrap.outputs.project_id
  account_id   = "${var.cluster_name}-nodes"
  display_name = "GKE Node SA for ${var.cluster_name}"

  depends_on = [google_project_service.iam_api]
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ])

  project = data.terraform_remote_state.bootstrap.outputs.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
