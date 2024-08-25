variable "region" {
  type    = string
  default = "europe-west3"
}

variable "gcp_project" {
  type    = string
  default = "level-racer-394516"
}

variable "gcp_dataset" {
  type    = string
  default = "CryptoPricing"
}

variable "project_name" {
  description = "Default project_name"
  type        = string
  default     = "tf-binance"
}

variable "credentials" {
  description = "Path to service account file"
  type = string
  default = "./service_account.json"
}