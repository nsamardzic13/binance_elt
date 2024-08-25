resource "google_bigquery_dataset" "bigqurry" {
  dataset_id    = var.gcp_dataset
  friendly_name = var.gcp_dataset
  description   = "This is a dataset used as a passion project for playing with Binance API"
  location      = var.region

  labels = {
    source  = "terraform-github"
    project = var.project_name
  }
}