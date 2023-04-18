provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source = "../../../modules/aws/core/globals"
  # source        = "imperva/dsf-globals/aws"
  # version       = "1.3.10" # latest release tag
}

module "key_pair" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.3.10" # latest release tag
  key_name_prefix          = "imperva-dsf-"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
}

locals {
  workstation_cidr_24        = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
  deployment_name_salted     = join("-", [var.deployment_name, module.globals.salt])
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr  != null ? var.workstation_cidr : local.workstation_cidr_24
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  mx_subnet                  = var.subnet_ids != null ? var.subnet_ids.mx_subnet_id : module.vpc[0].public_subnets[0]
  gw_subnet                  = var.subnet_ids != null ? var.subnet_ids.gw_subnet_id : module.vpc[0].private_subnets[0]
}

##############################
# Generating network
##############################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  count = var.subnet_ids == null ? 1 : 0

  name = "${local.deployment_name_salted}-${module.globals.current_user_name}"
  cidr = var.vpc_ip_range

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(module.globals.availability_zones, 0, 2)
  private_subnets = var.private_subnets_cidr_list
  public_subnets  = var.public_subnets_cidr_list
}

##############################
# Generating deployment
##############################
module "mx" {
  source              = "../../../modules/aws/mx"
  friendly_name       = join("-", [local.deployment_name_salted, "dam"])
  dam_version         = var.dam_version
  subnet_id           = local.mx_subnet
  license_file        = var.license_file
  key_pair            = module.key_pair.key_pair.key_pair_name
  secure_password     = local.web_console_admin_password
  mx_password         = local.web_console_admin_password
  sg_ingress_cidr     = local.workstation_cidr
  sg_ssh_cidr         = local.workstation_cidr
  sg_web_console_cidr = local.workstation_cidr
  attach_public_ip    = true
}

module "agent_gw" {
  count                  = 1
  source                 = "../../../modules/aws/agent-gw"
  friendly_name          = join("-", [local.deployment_name_salted, "dam"])
  dam_version            = var.dam_version
  subnet_id              = local.gw_subnet
  key_pair               = module.key_pair.key_pair.key_pair_name
  secure_password        = local.web_console_admin_password
  mx_password            = local.web_console_admin_password
  sg_ingress_cidr        = local.workstation_cidr
  sg_agent_cidr          = var.agent_cidr_list
  sg_ssh_cidr            = local.workstation_cidr
  management_server_host = module.mx.private_ip
}
