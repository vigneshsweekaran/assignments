locals {
  Name = "multi-tiered-web-application"
}

module "vpc" {
  source = "./modules/vpc"

  name  = local.Name
  tags  = {
    Env  = "dev"
  }
  vpc_network_cidr = "10.0.0.0/22"
 }
