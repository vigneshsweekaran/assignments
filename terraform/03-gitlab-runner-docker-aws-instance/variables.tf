variable "aws_region" {
  type = string
  description = "AWS region"
  default = "us-west-2"
}

variable "aws_profile" {
  type = string
  description = "AWS profile name"
  default = "test"
}

variable "reg_token" {
  type = string
  description = "Gitlab cicd registration token"
  sensitive = true
}