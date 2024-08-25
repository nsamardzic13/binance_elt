terraform {
  backend "gcs" {
    bucket      = "tf-my-backend-bucket"
    prefix      = "terraform/state"
    credentials = "service_account.json"
  }
}