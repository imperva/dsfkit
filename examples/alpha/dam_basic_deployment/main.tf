provider "aws" {
}

module "globals" {
  source  = "imperva/dsf-globals/aws"
  version = "1.5.0" # latest release tag

  tags = local.tags
}

module "key_pair" {
  source  = "imperva/dsf-globals/aws//modules/key_pair"
  version = "1.5.0" # latest release tag

  key_name_prefix      = "imperva-dsf-"
  private_key_filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
  tags                 = local.tags
}

locals {
  workstation_cidr_24    = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
  password               = var.password != null ? var.password : module.globals.random_password
  workstation_cidr       = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tags                   = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  mx_subnet_id           = var.subnet_ids != null ? var.subnet_ids.mx_subnet_id : module.vpc[0].public_subnets[0]
  gw_subnet_id           = var.subnet_ids != null ? var.subnet_ids.gw_subnet_id : module.vpc[0].private_subnets[0]
  gateway_group_name     = "gatewayGroup1"
  cluster_name           = "cluster1"
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
  tags                    = local.tags
}

##############################
# Generating deployment
##############################
module "mx" {
  source  = "imperva/dsf-mx/aws"
  version = "1.5.0" # latest release tag

  friendly_name                     = join("-", [local.deployment_name_salted, "mx"])
  dam_version                       = var.dam_version
  subnet_id                         = local.mx_subnet_id
  license_file                      = var.license_file
  key_pair                          = module.key_pair.key_pair.key_pair_name
  secure_password                   = local.password
  mx_password                       = local.password
  allowed_web_console_and_api_cidrs = local.workstation_cidr
  allowed_agent_gw_cidrs            = [data.aws_subnet.gw.cidr_block]
  allowed_ssh_cidrs                 = local.workstation_cidr
  hub_details                       = var.hub_details
  attach_persistent_public_ip       = true
  large_scale_mode                  = var.large_scale_mode

  create_server_group = var.agent_count > 0 ? true : false
  tags                = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agent_gw" {
  source  = "imperva/dsf-agent-gw/aws"
  version = "1.5.0" # latest release tag

  count = var.gw_count

  friendly_name                           = join("-", [local.deployment_name_salted, "agent", "gw", count.index])
  dam_version                             = var.dam_version
  subnet_id                               = local.gw_subnet_id
  key_pair                                = module.key_pair.key_pair.key_pair_name
  secure_password                         = local.password
  mx_password                             = local.password
  allowed_agent_cidrs                     = [data.aws_subnet.gw.cidr_block]
  allowed_mx_cidrs                        = [data.aws_subnet.mx.cidr_block]
  allowed_ssh_cidrs                       = [data.aws_subnet.mx.cidr_block]
  allowed_gw_clusters_cidrs               = [data.aws_subnet.gw.cidr_block]
  management_server_host_for_registration = module.mx.private_ip
  management_server_host_for_api_access   = module.mx.public_ip
  large_scale_mode                        = var.large_scale_mode
  gateway_group_name                      = local.gateway_group_name
  tags                                    = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agent_gw_cluster_setup" {
  source  = "imperva/dsf-agent-gw-cluster-setup/null"
  version = "1.5.0" # latest release tag

  cluster_name       = local.cluster_name
  gateway_group_name = local.gateway_group_name
  mx_details = {
    address  = module.mx.public_ip
    port     = 8083
    user     = "admin"
    password = local.password
  }
  depends_on = [
    module.agent_gw,
    module.mx
  ]
}

module "db_with_agent" {
  source  = "imperva/dsf-db-with-agent/aws"
  version = "1.5.0" # latest release tag
  count   = var.agent_count

  friendly_name = join("-", [local.deployment_name_salted, "db", "with", "agent", count.index])

  subnet_id         = local.gw_subnet_id
  key_pair          = module.key_pair.key_pair.key_pair_name
  allowed_ssh_cidrs = [format("%s/32", module.mx.private_ip)]

  registration_params = {
    agent_gateway_host = module.agent_gw[0].private_ip
    secure_password    = local.password
    server_group       = module.mx.configuration.default_server_group
    site               = module.mx.configuration.default_site
  }
  tags = local.tags
  depends_on = [
    module.agent_gw_cluster_setup
  ]
}
