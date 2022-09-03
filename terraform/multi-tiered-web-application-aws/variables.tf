variable "tags" {
  description = "Tags"
  type = map(string)
  default = {}
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type = string
  default = "10.0.0.0/22"
}

variable "rds_password" {
    description = "RDS password"
    type = string
    sensitive = true
}