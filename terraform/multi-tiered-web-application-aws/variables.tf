variable "tags" {
  description = "Tags"
  type = map(string)
  default = {}
}

variable "rds_password" {
    description = "RDS password"
    type = string
    sensitive = true
}