locals {
  region           = data.aws_region.current.name
  deployment_name  = join("-", [var.deployment_name, random_id.salt.hex])
  admin_password   = var.admin_password != null ? var.admin_password : random_password.admin_password.result
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", data.local_file.myip_file.content))]
  tarball_location = {
    "s3_bucket": var.tarball_s3_bucket
    "s3_key": var.tarball_s3_key
  }
  tags = {
      owner                 = local.deployment_name
      terraform_workspace   = terraform.workspace
      vendor                = "Imperva"
      product               = "EDSF"
      terraform             = "true"
      environment           = "demo"
  }
}

provider "aws" {
  default_tags {
    tags = local.tags
  }
}

resource "null_resource" "myip" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command         = "curl http://ipv4.icanhazip.com > myip-${terraform.workspace}"
    interpreter     = ["/bin/bash", "-c"]
  }
}


data "local_file" "myip_file" { # data "http" doesn't work as expected on Terraform cloud platform
    filename = "myip-${terraform.workspace}"
    depends_on = [
      resource.null_resource.myip
    ]
}

resource "random_password" "admin_password" {
  length           = 15
  special          = false
}

resource "random_id" "salt" {
  byte_length = 2
}

data "aws_region" "current" {}

##############################
# Generating ssh key pair
##############################

module "key_pair" {
  source             = "terraform-aws-modules/key-pair/aws"
  key_name_prefix    = "imperva-dsf-"
  create_private_key = true
}

resource "local_sensitive_file" "dsf_ssh_key_file" {
  content         = module.key_pair.private_key_pem
  file_permission = 400
  filename        = "ssh_keys/dsf_hub_ssh_key-${terraform.workspace}"
}

##############################
# Generating network
##############################

module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  name                = local.deployment_name
  cidr                = "10.0.0.0/16"

  enable_nat_gateway  = true
  single_nat_gateway  = true

  azs                 = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  tags                = local.tags
}

##############################
# Generating deployment
##############################

module "hub" {
  source          = "../../modules/hub"
  name            = local.deployment_name
  subnet_id       = module.vpc.public_subnets[0]
  key_pair        = module.key_pair.key_pair_name
  web_console_sg_ingress_cidr = var.web_console_cidr
  sg_ingress_cidr = local.workstation_cidr
  tarball_bucket_name = local.tarball_location.s3_bucket
}

module "agentless_gw" {
  count             = var.gw_count
  source            = "../../modules/gw"
  name              = join("-", [local.deployment_name, "gw", count.index])
  subnet_id         = module.vpc.private_subnets[0]
  key_pair          = module.key_pair.key_pair_name
  sg_ingress_cidr   = concat(local.workstation_cidr, ["${module.hub.private_address}/32"])
  tarball_bucket_name = local.tarball_location.s3_bucket
}

# ssh with bastion - https://www.jeffgeerling.com/blog/2022/using-ansible-playbook-ssh-bastion-jump-host
data "template_file" "hosts" {
  template = file("hosts.tpl")
  vars = {
    hub_address = module.hub.public_address
    gw_table = join("\n", [ for idx, val in module.agentless_gw : "gw-${idx}\tansible_ssh_host=${val.private_address}\tproxy=${module.hub.public_address}" ])
    ssh_key_path = resource.local_sensitive_file.dsf_ssh_key_file.filename
    sonarw_secret_name = module.hub.sonarw_secret.name
    sonarw_public_key = module.hub.sonarw_public_key
    tarball_s3_bucket = local.tarball_location.s3_bucket
    tarball_s3_key = local.tarball_location.s3_key
    installation_param_password = local.admin_password
    installation_param_display_name = local.deployment_name
  }
}

resource "local_file" "hosts_file" {
    content  = data.template_file.hosts.rendered
    filename = "hosts-${terraform.workspace}"
}

