locals {
  agent_ami_owner_linux    = "309956199498" // aws
  agent_ami_name_linux     = "RHEL-8.9.*"
  agent_ami_ssh_user_linux = "ec2-user"

  agent_ami_owner_windows  = "amazon"
  agent_ami_name_windows   = "Windows_Server-2022-English-Full-Base-*"
  agent_ami_ssh_user_windows = "Administrator"

  agent_ami_ssh_user = var.os_type == "Windows" ? local.agent_ami_ssh_user_windows : local.agent_ami_ssh_user_linux
}

data "aws_ami" "agent_ami_linux" {
  count = var.os_type == "Windows" ? 0 : 1
  most_recent = true
  name_regex  = local.agent_ami_name_linux

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = [local.agent_ami_owner_linux]
}

data "aws_ami" "agent_ami_windows" {
  count = var.os_type == "Windows" ? 1 : 0
  most_recent = true

  filter {
    name   = "name"
    values = [local.agent_ami_name_windows]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = [local.agent_ami_owner_windows]
}
