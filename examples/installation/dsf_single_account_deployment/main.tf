module "globals" {
  source  = "imperva/dsf-globals/aws"
  version = "1.5.5" # latest release tag

  sonar_version = var.sonar_version
  dra_version   = var.dra_version
}

locals {
  workstation_cidr_24    = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
  password               = var.password != null ? var.password : module.globals.random_password
  workstation_cidr       = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  additional_tags        = var.additional_tags != null ? { for item in var.additional_tags : split("=", item)[0] => split("=", item)[1] } : {}
  tags                   = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted }, local.additional_tags)

  hub_main_private_key_file_path          = var.hub_main_key_pair != null ? var.hub_main_key_pair.private_key_file_path : module.key_pair_hub_main[0].private_key_file_path
  hub_main_public_key_name                = var.hub_main_key_pair != null ? var.hub_main_key_pair.public_key_name : module.key_pair_hub_main[0].key_pair.key_pair_name
  hub_dr_private_key_file_path            = var.hub_dr_key_pair != null ? var.hub_dr_key_pair.private_key_file_path : module.key_pair_hub_dr[0].private_key_file_path
  hub_dr_public_key_name                  = var.hub_dr_key_pair != null ? var.hub_dr_key_pair.public_key_name : module.key_pair_hub_dr[0].key_pair.key_pair_name
  agentless_gw_main_private_key_file_path = var.agentless_gw_main_key_pair != null ? var.agentless_gw_main_key_pair.private_key_file_path : module.key_pair_agentless_gw_main[0].private_key_file_path
  agentless_gw_main_public_key_name       = var.agentless_gw_main_key_pair != null ? var.agentless_gw_main_key_pair.public_key_name : module.key_pair_agentless_gw_main[0].key_pair.key_pair_name
  agentless_gw_dr_private_key_file_path   = var.agentless_gw_dr_key_pair != null ? var.agentless_gw_dr_key_pair.private_key_file_path : module.key_pair_agentless_gw_dr[0].private_key_file_path
  agentless_gw_dr_public_key_name         = var.agentless_gw_dr_key_pair != null ? var.agentless_gw_dr_key_pair.public_key_name : module.key_pair_agentless_gw_dr[0].key_pair.key_pair_name
  mx_private_key_file_path                = var.mx_key_pair != null ? var.mx_key_pair.private_key_file_path : module.key_pair_mx[0].private_key_file_path
  mx_public_key_name                      = var.mx_key_pair != null ? var.mx_key_pair.public_key_name : module.key_pair_mx[0].key_pair.key_pair_name
  agent_gw_private_key_file_path          = var.agent_gw_key_pair != null ? var.agent_gw_key_pair.private_key_file_path : module.key_pair_agent_gw[0].private_key_file_path
  agent_gw_public_key_name                = var.agent_gw_key_pair != null ? var.agent_gw_key_pair.public_key_name : module.key_pair_agent_gw[0].key_pair.key_pair_name
  dra_admin_private_key_file_path         = var.dra_admin_key_pair != null ? var.dra_admin_key_pair.private_key_file_path : module.key_pair_dra_admin[0].private_key_file_path
  dra_admin_public_key_name               = var.dra_admin_key_pair != null ? var.dra_admin_key_pair.public_key_name : module.key_pair_dra_admin[0].key_pair.key_pair_name
  dra_analytics_private_key_file_path     = var.dra_analytics_key_pair != null ? var.dra_analytics_key_pair.private_key_file_path : module.key_pair_dra_analytics[0].private_key_file_path
  dra_analytics_public_key_name           = var.dra_analytics_key_pair != null ? var.dra_analytics_key_pair.public_key_name : module.key_pair_dra_analytics[0].key_pair.key_pair_name
}

##############################
# Generating ssh keys
##############################

module "key_pair_hub_main" {
  count                = var.hub_main_key_pair == null ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.5" # latest release tag
  key_name_prefix      = "imperva-dsf-hub-main"
  private_key_filename = "ssh_keys/dsf_ssh_key-hub-main-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.provider-1
  }
}

module "key_pair_hub_dr" {
  count                = var.hub_dr_key_pair == null ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.5" # latest release tag
  key_name_prefix      = "imperva-dsf-hub-dr"
  private_key_filename = "ssh_keys/dsf_ssh_key-hub-dr-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.provider-1
  }
}

module "key_pair_agentless_gw_main" {
  count                = var.agentless_gw_main_key_pair == null ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.5" # latest release tag
  key_name_prefix      = "imperva-dsf-gw-main"
  private_key_filename = "ssh_keys/dsf_ssh_key-agentless-gw-main-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.provider-2
  }
}

module "key_pair_agentless_gw_dr" {
  count                = var.agentless_gw_dr_key_pair == null ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.5" # latest release tag
  key_name_prefix      = "imperva-dsf-gw-dr"
  private_key_filename = "ssh_keys/dsf_ssh_key-agentless-gw-dr-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.provider-2
  }
}

module "key_pair_mx" {
  count                = var.mx_key_pair == null ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.5" # latest release tag
  key_name_prefix      = "imperva-dsf-mx"
  private_key_filename = "ssh_keys/dsf_ssh_key-mx-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.provider-1
  }
}

module "key_pair_agent_gw" {
  count                = var.agent_gw_key_pair == null ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.5" # latest release tag
  key_name_prefix      = "imperva-dsf-agent-gw"
  private_key_filename = "ssh_keys/dsf_ssh_key-agent-gw-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.provider-2
  }
}

module "key_pair_dra_admin" {
  count                = var.dra_admin_key_pair == null ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.5" # latest release tag
  key_name_prefix      = "imperva-dsf-dra-admin"
  private_key_filename = "ssh_keys/dsf_ssh_key-dra-admin-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.provider-1
  }
}

module "key_pair_dra_analytics" {
  count                = var.dra_analytics_key_pair == null ? 1 : 0
  source               = "imperva/dsf-globals/aws//modules/key_pair"
  version              = "1.5.5" # latest release tag
  key_name_prefix      = "imperva-dsf-dra-analytics"
  private_key_filename = "ssh_keys/dsf_ssh_key-dra-analytics-${terraform.workspace}"
  tags                 = local.tags
  providers = {
    aws = aws.provider-2
  }
}

