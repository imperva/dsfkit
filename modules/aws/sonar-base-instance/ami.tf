locals {
  ami_default = {
    id               = null
    owner_account_id = "309956199498"
    username         = "ec2-user"
    name             = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2"
  }

  ami = var.ami != null ? var.ami : local.ami_default

  ami_owner    = local.ami.owner_account_id != null ? local.ami.owner_account_id : "self"
  ami_name     = local.ami.name != null ? local.ami.name : "*"
  ami_id       = local.ami.id != null ? local.ami.id : "*"
  ami_username = local.ami.username
}

data "aws_ami" "selected-ami" {
  most_recent = true
  owners      = [local.ami_owner]

  filter {
    name   = "image-id"
    values = [local.ami_id]
  }

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