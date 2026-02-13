variable "app_name" {
  description = "The name of the app"
}

variable "email_domain" {
  description = "The domain used for sending emails"
}

variable "aws_region" {
  default     = "eu-west-3"
  description = "The region on which to deploy the AWS resources"
}
