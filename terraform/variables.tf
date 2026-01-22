variable "app_name" {
  description = "The name of the app"
}

variable "app_domain" {
  description = "The domain where the app is hosted"
}

variable "aws_region" {
  default     = "eu-west-3"
  description = "The region on which to deploy the AWS resources"
}
