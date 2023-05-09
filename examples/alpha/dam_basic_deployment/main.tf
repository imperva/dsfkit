provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source  = "imperva/dsf-globals/aws"
  version = "1.4.4" # latest release tag
}

module "key_pair" {
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.4" # latest release tag
  key_name_prefix          = "imperva-dsf-"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
}

locals {
  workstation_cidr_24        = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
  deployment_name_salted     = join("-", [var.deployment_name, module.globals.salt])
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  mx_subnet_id                  = var.subnet_ids != null ? var.subnet_ids.mx_subnet_id : module.vpc[0].public_subnets[0]
  gw_subnet_id                  = var.subnet_ids != null ? var.subnet_ids.gw_subnet_id : module.vpc[0].private_subnets[0]
}

data "aws_subnet" "mx" {
  id = local.mx_subnet_id
}

data "aws_subnet" "gw" {
  id = local.gw_subnet_id
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

  map_public_ip_on_launch = true
}

##############################
# Generating deployment
##############################
module "mx" {
  source  = "imperva/dsf-mx/aws"
  version = "1.4.4" # latest release tag
  friendly_name             = join("-", [local.deployment_name_salted, "mx"])
  dam_version               = var.dam_version
  subnet_id                 = local.mx_subnet_id
  license_file              = var.license_file
  key_pair                  = module.key_pair.key_pair.key_pair_name
  secure_password           = local.web_console_admin_password
  mx_password               = local.web_console_admin_password
  allowed_web_console_cidrs = local.workstation_cidr
  allowed_agent_gw_cidrs    = [data.aws_subnet.gw.cidr_block]
  allowed_ssh_cidrs         = local.workstation_cidr
  hub_details               = var.hub_details
  attach_persistent_public_ip          = true
  large_scale_mode          = var.large_scale_mode

  create_service_group = var.agent_count > 0 ? true : false
}

module "agent_gw" {
  source  = "imperva/dsf-agent-gw/aws"
  version = "1.4.4" # latest release tag
  count   = var.gw_count

  friendly_name                           = join("-", [local.deployment_name_salted, "agent", "gw", count.index])
  dam_version                             = var.dam_version
  subnet_id                               = local.gw_subnet_id
  key_pair                                = module.key_pair.key_pair.key_pair_name
  secure_password                         = local.web_console_admin_password
  mx_password                             = local.web_console_admin_password
  allowed_agent_cidrs                     = [data.aws_subnet.gw.cidr_block]
  allowed_mx_cidrs                        = [data.aws_subnet.mx.cidr_block]
  allowed_ssh_cidrs                       = [data.aws_subnet.mx.cidr_block]
  management_server_host_for_registration = module.mx.private_ip
  management_server_host_for_api_access   = module.mx.public_ip
  large_scale_mode                        = var.large_scale_mode
}

module "agent_monitored_db" {
  source = "../../../modules/aws/db-with-agent"
  count  = var.agent_count

  friendly_name = join("-", [local.deployment_name_salted, "agent", "monitored", "db", count.index])

  subnet_id         = local.gw_subnet_id
  key_pair          = module.key_pair.key_pair.key_pair_name
  allowed_ssh_cidrs = [format("%s/32", module.mx.private_ip)]

  registration_params = {
    agent_gateway_host = module.agent_gw[0].private_ip
    secure_password    = local.web_console_admin_password
    server_group       = module.mx.configuration.default_server_group
    site               = module.mx.configuration.default_site
  }
}
