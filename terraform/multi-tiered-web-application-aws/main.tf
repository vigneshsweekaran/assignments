locals {
  Name = "multi-tiered-web-application"
}

module "vpc" {
  source = "./modules/vpc"

  name  = local.Name
  tags  = {
    Name = local.Name
    Env  = "dev"
  }
  vpc_network_cidr = "10.0.0.0/22"
 }
