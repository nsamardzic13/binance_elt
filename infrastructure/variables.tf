variable "project_name" {
  description = "Default project_name"
  type        = string
  default     = "tf-binance"
}

variable "sns_email_address" {
  type    = string
  default = "nikola.samardzic1997+AWS@gmail.com"
}

variable "lambda_layers" {
  type = list(string)
  default = [
    "arn:aws:lambda:eu-central-1:770693421928:layer:Klayers-p311-boto3:12"
  ]
}

variable "image_name" {
  type    = string
  default = "docker.io/nidjo13/binance_elt:latest"
}