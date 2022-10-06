locals {
  key_name         = "gitlab-runner"
  private_key_path = "~/.ssh/id_rsa"
}

data "aws_region" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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
  ami                    = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [aws_security_group.gitlab-runner.id]
  key_name               = local.key_name

  tags = {
    Name        = "gitlab-runner"
  }
}

resource "local_file" "playbbok" {
  content = templatefile("playbook.yaml.tftpl", { runner_version = "${var.runner_version}", runner_token = "${var.runner_token}", runner_tag = "${var.runner_tag}" })
  filename = "${path.module}/playbook.yaml"
}

resource "null_resource" "ansible-install-gitlab-runner" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Verified ssh connection'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(local.private_key_path)
      host        = aws_instance.gitlab-runner.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook  -i ${aws_instance.gitlab-runner.public_ip}, --private-key ${local.private_key_path} playbook.yaml"
  }
}
