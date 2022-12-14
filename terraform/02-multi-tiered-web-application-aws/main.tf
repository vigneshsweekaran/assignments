locals {
  Name = "multi-tiered-web-application"
}

module "vpc" {
  source = "./modules/vpc"

  name  = local.Name
  tags  = var.tags
  vpc_network_cidr = var.cidr_block
 }

# AWS RDS private db subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = local.Name
  subnet_ids = module.vpc.private_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = local.Name
    }
  )
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

  tags = merge(
    var.tags,
    {
      Name = local.Name
    }
  )
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

# SG for EC2 instances 
resource "aws_security_group" "sg-instance" {
  name        = "instances-sg"
  description = "Load balancer security group"
  vpc_id      = module.vpc.vpc_id
  
  # Allow only port 80 from alb sg
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.sg-alb.id]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = local.Name
    }
  )
}

# EC2 Instance in private subnet
# resource "aws_instance" "instances" {
#   count = 2
#   subnet_id = module.vpc.private_subnet_ids[count.index]
# 	ami = "ami-0d70546e43a941d70"
# 	instance_type = "t2.micro"
#   user_data = "${file("init.sh")}"
# 	tags = merge(
#     var.tags,
#     {
#       Name = "${local.Name}-${count.index}"
#     }
#   )
# }

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2 Launch Configuration
resource "aws_launch_configuration" "web-application" {
  name_prefix     = "${local.Name}-"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  user_data       = file("init.sh")
  security_groups = [aws_security_group.sg-instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling group
resource "aws_autoscaling_group" "web-application" {
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.web-application.name
  vpc_zone_identifier  = module.vpc.private_subnet_ids
}

# SG for AWS load balancer
resource "aws_security_group" "sg-alb" {
  name        = "alb-sg"
  description = "Load balancer security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic only to instances sg.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_block}"]
  }

  tags = merge(
    var.tags,
    {
      Name = local.Name
    }
  )
}

# AWS load balancer - public
resource "aws_alb" "web-application" {
  name            = local.Name
  security_groups = ["${aws_security_group.sg-alb.id}"]
  subnets         = module.vpc.public_subnet_ids
  tags = merge(
    var.tags,
    {
      Name = local.Name
    }
  )
}

resource "aws_alb_target_group" "web-application" {
  name     = local.Name
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/"
    port = 80
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.web-application.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.web-application.arn}"
    type             = "forward"
  }
}

resource "aws_autoscaling_attachment" "web-application" {
  autoscaling_group_name = aws_autoscaling_group.web-application.id
  alb_target_group_arn   = aws_alb_target_group.web-application.arn
}