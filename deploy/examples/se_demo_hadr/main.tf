provider "aws" {
  default_tags {
    tags = local.tags
  }
}

module "globals" {
  source = "../../modules/core/globals"
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  admin_password   = var.admin_password != null ? var.admin_password : module.globals.random_password
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  database_cidr    = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location = {
    "s3_bucket" : var.tarball_s3_bucket
    "s3_key" : var.tarball_s3_key
  }
  tags = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

##############################
# Generating network
##############################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = local.deployment_name_salted
  cidr   = var.vpc_ip_range

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

##############################
# Generating deployment
##############################

module "hub" {
  source                        = "../../modules/hub"
  name                          = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                     = module.vpc.public_subnets[0]
  key_pair                      = module.globals.key_pair.key_pair_name
  web_console_sg_ingress_cidr   = var.web_console_cidr
  sg_ingress_cidr               = concat(local.workstation_cidr, ["${module.hub_secondary.private_address}/32"])
  installation_location         = local.tarball_location
  admin_password                = local.admin_password
  ssh_key_pair_path             = module.globals.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  depends_on = [
    module.vpc
  ]
}

module "hub_secondary" {
  source                        = "../../modules/hub"
  name                          = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                     = module.vpc.public_subnets[1]
  key_pair                      = module.globals.key_pair.key_pair_name
  web_console_sg_ingress_cidr   = var.web_console_cidr
  sg_ingress_cidr               = concat(local.workstation_cidr, ["${module.hub.private_address}/32"])
  hadr_secondary_node           = true
  hadr_main_hub_sonarw_secret   = module.hub.sonarw_secret
  hadr_main_sonarw_public_key   = module.hub.sonarw_public_key
  installation_location         = local.tarball_location
  admin_password                = local.admin_password
  ssh_key_pair_path             = module.globals.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group" {
  count                         = var.gw_count
  source                        = "../../modules/agentless-gw"
  name                          = join("-", [local.deployment_name_salted, "gw", count.index])
  subnet_id                     = module.vpc.private_subnets[0]
  key_pair                      = module.globals.key_pair.key_pair_name
  sg_ingress_cidr               = concat(local.workstation_cidr, ["${module.hub.private_address}/32", "${module.hub_secondary.private_address}/32"])
  installation_location         = local.tarball_location
  admin_password                = local.admin_password
  ssh_key_pair_path             = module.globals.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  sonarw_public_key             = module.hub.sonarw_public_key
  sonarw_secret_name            = module.hub.sonarw_secret.name
  proxy_address                 = module.hub.public_address
  depends_on = [
    module.vpc
  ]
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub.public_address, module.hub_secondary.public_address],
    concat(
      [for idx, val in module.agentless_gw_group : val.private_address]
    )
  )
}

module "gw_attachments" {
  count               = length(local.hub_gw_combinations)
  source              = "../../modules/gw-attachment"
  gw                  = local.hub_gw_combinations[count.index][1]
  hub                 = local.hub_gw_combinations[count.index][0]
  hub_ssh_key_path    = module.globals.key_pair_private_pem.filename
  installation_source = "${local.tarball_location.s3_bucket}/${local.tarball_location.s3_key}"
  depends_on = [
    module.hub,
    module.hub_secondary,
    module.agentless_gw_group,
  ]
}

module "hadr" {
  source                       = "../../modules/hadr"
  dsf_hub_primary_public_ip    = module.hub.public_address
  dsf_hub_primary_private_ip   = module.hub.private_address
  dsf_hub_secondary_public_ip  = module.hub_secondary.public_address
  dsf_hub_secondary_private_ip = module.hub_secondary.private_address
  ssh_key_path                 = module.globals.key_pair_private_pem.filename
  depends_on = [
    module.gw_attachments
    module.gw_attachments
    module.hub,
    module.hub_secondary,
  ]
}
