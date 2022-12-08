provider "aws" {
  default_tags {
    tags = local.tags
  }
  profile = var.aws_profile_hub
  region  = var.aws_region_hub
}

provider "aws" {
  default_tags {
    tags = local.tags
  }
  profile = var.aws_profile_gw
  region  = var.aws_region_gw
  alias   = "gw"
}

module "globals" {
  source = "../../modules/core/globals"
}

locals {
  workstation_cidr_24 = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  admin_password   = var.admin_password != null ? var.admin_password : module.globals.random_password
  workstation_cidr = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tarball_location = {
    "s3_bucket" : var.tarball_s3_bucket
    "s3_key" : var.tarball_s3_key
  }
  tags = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
}

##############################
# Generating ssh keys
##############################

module "key_pair_hub" {
  source                   = "../../modules/core/key_pair"
  key_name_prefix          = "imperva-dsf-hub"
  create_private_key       = true
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-hub-${terraform.workspace}"
}

module "key_pair_gw" {
  source                   = "../../modules/core/key_pair"
  key_name_prefix          = "imperva-dsf-gw"
  create_private_key       = true
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw-${terraform.workspace}"
  providers = {
    aws = aws.gw
  }
}

##############################
# Generating deployment
##############################

module "hub" {
  source                        = "../../modules/hub"
  name                          = join("-", [local.deployment_name_salted, "hub", "primary"])
  subnet_id                     = var.subnet_hub
  key_pair                      = module.key_pair_hub.key_pair.key_pair_name
  web_console_cidr              = var.web_console_cidr
  sg_ingress_cidr               = local.workstation_cidr
  installation_location         = local.tarball_location
  admin_password                = local.admin_password
  ssh_key_path                  = module.key_pair_hub.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  ebs_details                   = var.hub_ebs_details
  public_ip                     = false
}

module "agentless_gw_group" {
  count                         = var.gw_count
  source                        = "../../modules/agentless-gw"
  name                          = join("-", [local.deployment_name_salted, "gw", count.index])
  subnet_id                     = var.subnet_gw
  key_pair                      = module.key_pair_gw.key_pair.key_pair_name
  sg_ingress_cidr               = concat(local.workstation_cidr, ["${module.hub.private_address}/32"])
  installation_location         = local.tarball_location
  admin_password                = local.admin_password
  ssh_key_path                  = module.key_pair_gw.key_pair_private_pem.filename
  proxy_private_key             = module.key_pair_hub.key_pair_private_pem.filename
  additional_install_parameters = var.additional_install_parameters
  sonarw_public_key             = module.hub.sonarw_public_key
  proxy_address                 = module.hub.private_address
  ebs_details                   = var.gw_group_ebs_details

  providers = {
    aws = aws.gw
  }
}

module "gw_attachments" {
  for_each            = { for idx, val in module.agentless_gw_group : idx => val }
  source              = "../../modules/gw-attachment"
  gw                  = each.value.private_address
  hub                 = module.hub.private_address
  hub_ssh_key_path    = module.key_pair_hub.key_pair_private_pem.filename
  gw_ssh_key_path     = module.key_pair_gw.key_pair_private_pem.filename
  installation_source = "${local.tarball_location.s3_bucket}/${local.tarball_location.s3_key}"
  depends_on = [
    module.hub,
    module.agentless_gw_group,
  ]
}

module "statistics" {
  source = "../../modules/statistics"
}
