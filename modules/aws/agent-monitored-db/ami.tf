locals {
  ami_owner    = "099720109477" # Amazon
  ami_name     = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
  ami_ssh_user = "ubuntu"
}

data "aws_ami" "selected-ami" {
  most_recent = true
  owners      = [local.ami_owner]

  filter {
    name   = "name"
    values = [local.ami_name]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}