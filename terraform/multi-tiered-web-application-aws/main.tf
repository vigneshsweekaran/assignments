locals {
  Name = "multi-tiered-web-application"
}

module "vpc" {
  source = "./modules/vpc"

  name  = local.Name
  tags  = var.tags
  vpc_network_cidr = "10.0.0.0/22"
 }

# AWS RDS private db subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = local.Name
  subnet_ids = module.vpc.private_subnet_ids

  tags = var.tags
}

# AWS RDS
resource "aws_db_instance" "db_instance" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  identifier           = lower(local.Name)
  username             = "admin"
  password             = var.rds_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

# AWS Elasticcache redis private db subnet group
resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = local.Name
  subnet_ids = module.vpc.private_subnet_ids
}

# AWS Elactic cache - Redis
resource "aws_elasticache_cluster" "example" {
  cluster_id           = "cluster-example"
  subnet_group_name    = aws_elasticache_subnet_group.elasticache_subnet_group.name
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
}

# EC2 Instance in private subnet
resource "aws_instance" "my-instance" {
  count = 2
  subnet_id = module.vpc.private_subnet_ids[count.index]
	ami = "ami-0d70546e43a941d70"
	instance_type = "t2.micro"
  user_data = "${file("init.sh")}"
	tags = var.tags
}