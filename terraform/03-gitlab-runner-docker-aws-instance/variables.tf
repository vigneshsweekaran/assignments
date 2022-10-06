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

variable "runner_version" {
  type = string
  description = "Gitlab runner version"
}

variable "runner_token" {
  type = string
  description = "Gitlab runner registration token"
  sensitive = true
}

variable "runner_tag" {
  type = string
  description = "Gitlab runner tag"
}