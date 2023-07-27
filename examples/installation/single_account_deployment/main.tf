provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region_hub
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.4.6" # latest release tag
  sonar_version = var.sonar_version
  tags          = local.tags
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tarball_location           = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  additional_tags            = var.additional_tags != null ? { for item in var.additional_tags : split("=", item)[0] => split("=", item)[1] } : {}
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted }, local.additional_tags)
  should_create_hub_key_pair = var.hub_key_pem_details == null ? true : false
}

##############################
# Generating ssh keys
##############################
module "key_pair_hub" {
  count                    = local.should_create_hub_key_pair ? 1 : 0
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.6" # latest release tag
  key_name_prefix          = "imperva-dsf-hub"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-hub-${terraform.workspace}"
  tags                     = local.tags
}

locals {
  hub_private_key_pem_file_path = var.hub_key_pem_details != null ? var.hub_key_pem_details.private_key_pem_file_path : module.key_pair_hub[0].private_key_file_path
  hub_public_key_name           = var.hub_key_pem_details != null ? var.hub_key_pem_details.public_key_name : module.key_pair_hub[0].key_pair.key_pair_name
  gw_private_key_pem_file_path  = var.GROUPA_gw_key_pem_details.private_key_pem_file_path
  gw_public_key_name            = var.GROUPA_gw_key_pem_details.public_key_name
}

data "aws_subnet" "primary_hub" {
  id = var.subnet_hub_primary
}

data "aws_subnet" "secondary_hub" {
  id = var.subnet_hub_secondary
}

##############################
# Generating deployment
##############################
module "hub_primary" {
  source                                 = "../../../modules/aws/hub"
  friendly_name                          = join("-", [local.deployment_name_salted, "hub", "pri"])
  subnet_id                              = var.subnet_hub_primary
  security_group_ids                     = var.security_group_ids_hub
  binaries_location                      = local.tarball_location
  web_console_admin_password             = local.web_console_admin_password
  web_console_admin_password_secret_name = var.web_console_admin_password_secret_name
  instance_type                          = var.hub_instance_type
  ebs                                    = var.hub_ebs_details
  ami                                    = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_private_key_pem_file_path
    ssh_public_key_name       = local.hub_public_key_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.secondary_hub.cidr_block]
  allowed_agentless_gw_cidrs        = concat(
    [data.aws_subnet.GROUPA_subnet_gw.cidr_block],
    [data.aws_subnet.GROUPB_subnet_gw.cidr_block],
    [data.aws_subnet.GROUPC_subnet_gw.cidr_block],
    [data.aws_subnet.GROUPD_subnet_gw.cidr_block]
    )
  allowed_all_cidrs                 = local.workstation_cidr

  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  internal_private_key_secret_name  = var.internal_hub_private_key_secret_name
  internal_public_key               = try(trimspace(file(var.internal_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  tags                              = local.tags
}

module "hub_secondary" {
  source                                 = "../../../modules/aws/hub"
  friendly_name                          = join("-", [local.deployment_name_salted, "hub", "sec"])
  subnet_id                              = var.subnet_hub_secondary
  security_group_ids                     = var.security_group_ids_hub
  binaries_location                      = local.tarball_location
  web_console_admin_password             = local.web_console_admin_password
  web_console_admin_password_secret_name = var.web_console_admin_password_secret_name
  instance_type                          = var.hub_instance_type
  ebs                                    = var.hub_ebs_details
  ami                                    = var.ami
  hadr_secondary_node                    = true
  sonarw_public_key                      = module.hub_primary.sonarw_public_key
  sonarw_private_key                     = module.hub_primary.sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_private_key_pem_file_path
    ssh_public_key_name       = local.hub_public_key_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.primary_hub.cidr_block]
  allowed_agentless_gw_cidrs        = concat(
    [data.aws_subnet.GROUPA_subnet_gw.cidr_block],
    [data.aws_subnet.GROUPB_subnet_gw.cidr_block],
    [data.aws_subnet.GROUPC_subnet_gw.cidr_block],
    [data.aws_subnet.GROUPD_subnet_gw.cidr_block]
    )
  allowed_all_cidrs                 = local.workstation_cidr

  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  internal_private_key_secret_name  = var.internal_hub_private_key_secret_name
  internal_public_key               = try(trimspace(file(var.internal_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  tags                              = local.tags
}

module "hub_hadr" {
  source                       = "imperva/dsf-hadr/null"
  version                      = "1.4.6" # latest release tag
  sonar_version                = module.globals.tarball_location.version
  dsf_primary_ip               = module.hub_primary.private_ip
  dsf_primary_private_ip       = module.hub_primary.private_ip
  dsf_secondary_ip             = module.hub_secondary.private_ip
  dsf_secondary_private_ip     = module.hub_secondary.private_ip
  ssh_key_path                 = local.hub_private_key_pem_file_path
  ssh_user                     = module.hub_primary.ssh_user
  terraform_script_path_folder = var.terraform_script_path_folder
  depends_on = [
    module.hub_primary,
    module.hub_secondary
  ]
}

locals {
  gws = merge(
    {for idx, val in module.GROUPA_agentless_gw_group : "agentless-gw-us-west-2-${idx}" => val},
    {for idx, val in module.GROUPB_agentless_gw_group : "agentless-gw-us-west-1-${idx}" => val},
    {for idx, val in module.GROUPC_agentless_gw_group : "agentless-gw-us-east-1-${idx}" => val},
    {for idx, val in module.GROUPD_agentless_gw_group : "agentless-gw-us-east-2-${idx}" => val},
  )
  gws_set = values(local.gws)
  hubs_set = [
    module.hub_primary,
    module.hub_secondary
  ]
  hubs_keys = [
    "hub-primary",
    "hub-secondary",
  ]

  hub_gw_combinations_values = setproduct(local.hubs_set, local.gws_set)
  hub_gw_combinations_keys_ = setproduct(local.hubs_keys, keys(local.gws))
  hub_gw_combinations_keys = [for v in local.hub_gw_combinations_keys_: "${v[0]}-${v[1]}"]

  hub_gw_combinations = zipmap(local.hub_gw_combinations_keys, local.hub_gw_combinations_values)
}

module "federation" {
  for_each = local.hub_gw_combinations
  source  = "imperva/dsf-federation/null"
  version = "1.4.6" # latest release tag
  gw_info = {
    gw_ip_address           = each.value[1].private_ip
    gw_private_ssh_key_path = local.gw_private_key_pem_file_path
    gw_ssh_user             = each.value[1].ssh_user
  }
  hub_info = {
    hub_ip_address           = each.value[0].private_ip
    hub_private_ssh_key_path = local.hub_private_key_pem_file_path
    hub_ssh_user             = each.value[0].ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.GROUPA_agentless_gw_group,
    module.GROUPB_agentless_gw_group,
    module.GROUPC_agentless_gw_group,
    module.GROUPD_agentless_gw_group
  ]
}
