locals {
  key_name         = "gitlab-runner"
  private_key_path = "~/.ssh/id_rsa"
}

data "aws_region" "current" {}

data "aws_ami" "amazonlinux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_key_pair" "gitlab-runner" {
  key_name = local.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "gitlab-runner" {
  name        = "gitlab-runner"
  description = "Allow ssh"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gitlab-runner"
  }
}

resource "aws_instance" "gitlab-runner" {
  instance_type          = "t2.medium"
  ami                    = data.aws_ami.amazonlinux2.id
  vpc_security_group_ids = [aws_security_group.gitlab-runner.id]
  key_name               = local.key_name

  tags = {
    Name        = "gitlab-runner"
  }
}

resource "null_resource" "ansible-install-gitlab-runner" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Verified ssh connection'"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(local.private_key_path)
      host        = aws_instance.gitlab-runner.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook  -i ${aws_instance.gitlab-runner.public_ip}, --private-key ${local.private_key_path} playbook.yaml"
  }
}
