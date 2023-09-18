provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

module "globals" {
  source        = "imperva/dsf-globals/aws"
  version       = "1.5.4" # latest release tag
  sonar_version = var.sonar_version
}

data "aws_availability_zones" "available" { state = "available" }

locals {
  workstation_cidr_24 = try(module.globals.my_ip != null ? [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))] : null, null)
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  password                   = var.password != null ? var.password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tarball_location           = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  additional_tags            = var.additional_tags != null ? { for item in var.additional_tags : split("=", item)[0] => split("=", item)[1] } : {}
  tags                       = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted }, local.additional_tags)
  should_create_hub_key_pair = var.hub_key_pair == null ? true : false
  should_create_gw_key_pair  = var.gw_key_pair == null ? true : false
}

##############################
# Generating ssh keys
##############################
module "key_pair_hub" {
  count                = local.should_create_hub_key_pair ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.4" # latest release tag
  key_name_prefix      = "imperva-dsf-hub"
  private_key_filename = "ssh_keys/dsf_ssh_key-hub-${terraform.workspace}"
  tags                 = local.tags
}

module "key_pair_gw" {
  count                = local.should_create_gw_key_pair ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.4" # latest release tag
  key_name_prefix      = "imperva-dsf-gw"
  private_key_filename = "ssh_keys/dsf_ssh_key-gw-${terraform.workspace}"
  tags                 = local.tags
}

locals {
  hub_private_key_file_path = var.hub_key_pair != null ? var.hub_key_pair.private_key_file_path : module.key_pair_hub[0].private_key_file_path
  hub_public_key_name       = var.hub_key_pair != null ? var.hub_key_pair.public_key_name : module.key_pair_hub[0].key_pair.key_pair_name
  gw_private_key_file_path  = var.gw_key_pair != null ? var.gw_key_pair.private_key_file_path : module.key_pair_gw[0].private_key_file_path
  gw_public_key_name        = var.gw_key_pair != null ? var.gw_key_pair.public_key_name : module.key_pair_gw[0].key_pair.key_pair_name
}

data "aws_subnet" "main_hub" {
  id = var.subnet_hub_main
}

data "aws_subnet" "dr_hub" {
  id = var.subnet_hub_dr
}

data "aws_subnet" "subnet_gw" {
  id = var.subnet_gw
}

##############################
# Generating deployment
##############################
module "hub_main" {
  source               = "imperva/dsf-hub/aws"
  version              = "1.5.4" # latest release tag
  friendly_name        = join("-", [local.deployment_name_salted, "hub", "main"])
  subnet_id            = var.subnet_hub_main
  security_group_ids   = var.security_group_ids_hub
  binaries_location    = local.tarball_location
  password             = local.password
  password_secret_name = var.password_secret_name
  instance_type        = var.hub_instance_type
  ebs                  = var.hub_ebs_details
  ami                  = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_private_key_file_path
    ssh_public_key_name       = local.hub_public_key_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.dr_hub.cidr_block]
  allowed_agentless_gw_cidrs        = [data.aws_subnet.subnet_gw.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr

  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_hub_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  tags                              = local.tags
}

module "hub_dr" {
  source                          = "imperva/dsf-hub/aws"
  version                         = "1.5.4" # latest release tag
  friendly_name                   = join("-", [local.deployment_name_salted, "hub", "DR"])
  subnet_id                       = var.subnet_hub_dr
  security_group_ids              = var.security_group_ids_hub
  binaries_location               = local.tarball_location
  password                        = local.password
  password_secret_name            = var.password_secret_name
  instance_type                   = var.hub_instance_type
  ebs                             = var.hub_ebs_details
  ami                             = var.ami
  hadr_dr_node             = true
  main_node_sonarw_public_key  = module.hub_main.sonarw_public_key
  main_node_sonarw_private_key = module.hub_main.sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = local.hub_private_key_file_path
    ssh_public_key_name       = local.hub_public_key_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.main_hub.cidr_block]
  allowed_agentless_gw_cidrs        = [data.aws_subnet.subnet_gw.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr

  skip_instance_health_verification = var.hub_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_hub_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_hub_public_key_file_path)), null)
  instance_profile_name             = var.hub_instance_profile_name
  tags                              = local.tags
}

module "agentless_gw" {
  count                 = var.gw_count
  source                = "imperva/dsf-agentless-gw/aws"
  version               = "1.5.4" # latest release tag
  friendly_name         = join("-", [local.deployment_name_salted, "gw", count.index])
  subnet_id             = var.subnet_gw
  security_group_ids    = var.security_group_ids_gw
  instance_type         = var.gw_instance_type
  ebs                   = var.agentless_gw_ebs_details
  binaries_location     = local.tarball_location
  password              = local.password
  password_secret_name  = var.password_secret_name
  hub_sonarw_public_key = module.hub_main.sonarw_public_key
  ami                   = var.ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.gw_private_key_file_path
    ssh_public_key_name       = local.gw_public_key_name
  }
  allowed_hub_cidrs = [data.aws_subnet.main_hub.cidr_block, data.aws_subnet.dr_hub.cidr_block]
  allowed_all_cidrs = local.workstation_cidr
  ingress_communication_via_proxy = var.use_hub_as_proxy ? {
    proxy_address              = module.hub_main.private_ip
    proxy_private_ssh_key_path = local.hub_private_key_file_path
    proxy_ssh_user             = module.hub_main.ssh_user
  } : null
  skip_instance_health_verification = var.gw_skip_instance_health_verification
  terraform_script_path_folder      = var.terraform_script_path_folder
  sonarw_private_key_secret_name    = var.sonarw_gw_private_key_secret_name
  sonarw_public_key_content         = try(trimspace(file(var.sonarw_gw_public_key_file_path)), null)
  instance_profile_name             = var.gw_instance_profile_name
  tags                              = local.tags
}

module "hub_hadr" {
  source                       = "imperva/dsf-hadr/null"
  version                      = "1.5.4" # latest release tag
  sonar_version                = module.globals.tarball_location.version
  dsf_main_ip               = module.hub_main.private_ip
  dsf_main_private_ip       = module.hub_main.private_ip
  dsf_dr_ip             = module.hub_dr.private_ip
  dsf_dr_private_ip     = module.hub_dr.private_ip
  ssh_key_path                 = local.hub_private_key_file_path
  ssh_user                     = module.hub_main.ssh_user
  terraform_script_path_folder = var.terraform_script_path_folder
  depends_on = [
    module.hub_main,
    module.hub_dr
  ]
}

locals {
  hub_gw_combinations = setproduct(
    [module.hub_main, module.hub_dr],
    concat(
      [for idx, val in module.agentless_gw : val]
    )
  )
}

module "federation" {
  count   = length(local.hub_gw_combinations)
  source  = "imperva/dsf-federation/null"
  version = "1.5.4" # latest release tag

  hub_info = {
    hub_ip_address           = local.hub_gw_combinations[count.index][0].private_ip
    hub_private_ssh_key_path = local.hub_private_key_file_path
    hub_ssh_user             = local.hub_gw_combinations[count.index][0].ssh_user
  }
  gw_info = {
    gw_ip_address           = local.hub_gw_combinations[count.index][1].private_ip
    gw_private_ssh_key_path = local.gw_private_key_file_path
    gw_ssh_user             = local.hub_gw_combinations[count.index][1].ssh_user
  }
  gw_proxy_info = var.use_hub_as_proxy ? {
    proxy_address              = module.hub_main.private_ip
    proxy_private_ssh_key_path = local.hub_private_key_file_path
    proxy_ssh_user             = module.hub_main.ssh_user
  } : null
  depends_on = [
    module.hub_hadr,
    module.agentless_gw
  ]
}
