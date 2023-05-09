locals {
  ami_owner    = local.os_params[local.os_type].ami_owner
  ami_name     = local.os_params[local.os_type].ami_name
  ami_ssh_user = local.os_params[local.os_type].ami_ssh_user
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