provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
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
# Generating network
##############################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = true
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

resource "aws_instance" "installer_machine" {
  ami                           = data.aws_ami.installer-ami.image_id
  instance_type                 = var.ec2_instance_type
  key_name                      = module.key_pair.key_pair_name
  user_data                     = templatefile("${path.module}/prepare_installer.tpl", {
    access_key = var.aws_access_key_id
    secret_key = var.aws_secret_access_key
    region = var.aws_region
    example_name = var.example_name
    web_console_cidr= var.web_console_cidr != null ? var.web_console_cidr : format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", data.http.myip.response_body))
  })
  associate_public_ip_address = true
  tags = {
    Name = "dsf_installer_machine"
  }
}