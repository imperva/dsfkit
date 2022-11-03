provider "aws" {
  access_key = var._1_aws_access_key_id
  secret_key = var._2_aws_secret_access_key
  region     = var._3_aws_region
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_region" "current" {}

locals {
  region           = data.aws_region.current.name
}

##############################
# Generating ssh key pair
##############################

module "key_pair" {
  source             = "terraform-aws-modules/key-pair/aws"
  key_name_prefix    = "imperva-dsf-"
  create_private_key = true
}

resource "local_sensitive_file" "installer_ssh_key" {
  content         = module.key_pair.private_key_pem
  file_permission = 400
  filename        = "ssh_keys/installer_ssh_key"
}

##############################
# Generating deployment
##############################


locals {
  disk_size_app         = 100
  ebs_state_disk_type   = "gp3"
  ebs_state_iops        = 16000
  ebs_state_throughput  = 1000
}


data "aws_ami" "installer-ami" {
  most_recent = true
  owners      = ["309956199498"] # Amazon

  filter {
    name   = "name"
    values = ["RHEL-7.9*"]
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

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", data.http.myip.response_body))]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dsf_installer_machine-sg"
  }
}

resource "aws_instance" "installer_machine" {
  ami                           = data.aws_ami.installer-ami.image_id
  instance_type                 = var.ec2_instance_type
  key_name                      = module.key_pair.key_pair_name
  user_data                     = templatefile("${path.module}/prepare_installer.tpl", {
    access_key = var._1_aws_access_key_id
    secret_key = var._2_aws_secret_access_key
    region = var._3_aws_region
    example_name = var.example_name
    web_console_cidr= var.web_console_cidr != null ? var.web_console_cidr : format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", data.http.myip.response_body))
  })
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "dsf_installer_machine"
  }
}