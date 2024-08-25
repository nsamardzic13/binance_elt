terraform {
  backend "gcs" {
    bucket      = "tf-my-backend-bucket"
    prefix      = "terraform/state"
    credentials = file("${var.credentials}")
  }
}