locals {
  database_cidr    = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location = module.globals.tarball_location
}

module "hub" {
  source  = "imperva/dsf-hub/aws"
  version = "1.4.5" # latest release tag
  count   = var.enable_dsf_hub ? 1 : 0

  friendly_name                = join("-", [local.deployment_name_salted, "hub"])
  subnet_id                    = local.hub_subnet_id
  binaries_location            = local.tarball_location
  web_console_admin_password   = local.password
  ebs                          = var.hub_ebs_details
  attach_persistent_public_ip  = true
  use_public_ip                = true
  should_generate_access_token = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_agentless_gw_cidrs        = [data.aws_subnet.agentless_gw.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  tags                              = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.4.5" # latest release tag
  count   = var.agentless_gw_count

  friendly_name              = join("-", [local.deployment_name_salted, "agentless", "gw", count.index])
  subnet_id                  = local.agentless_gw_subnet_id
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.password
  hub_sonarw_public_key      = module.hub[0].sonarw_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_hub_cidrs = [data.aws_subnet.hub.cidr_block]
  allowed_all_cidrs = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc,
  ]
}

module "federation" {
  source   = "imperva/dsf-federation/null"
  version  = "1.4.5" # latest release tag
  for_each = { for idx, val in module.agentless_gw_group : idx => val }

  gw_info = {
    gw_ip_address           = each.value.private_ip
    gw_private_ssh_key_path = module.key_pair.private_key_file_path
    gw_ssh_user             = each.value.ssh_user
  }
  hub_info = {
    hub_ip_address           = module.hub[0].public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub[0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  depends_on = [
    module.hub,
    module.agentless_gw_group,
  ]
}

module "rds_mysql" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mysql-db"
  version = "1.4.5" # latest release tag
  count   = contains(var.db_types_to_onboard, "RDS MySQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr
  tags                         = local.tags
}

module "rds_mssql" {
  count   = contains(var.db_types_to_onboard, "RDS MsSQL") ? 1 : 0
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mssql-db"
  version = "1.4.5" # latest release tag

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr

  tags = local.tags
  providers = {
    aws                       = aws,
    aws.poc_scripts_s3_region = aws.poc_scripts_s3_region
  }
}

module "db_onboarding" {
  source   = "imperva/dsf-poc-db-onboarder/aws"
  version  = "1.4.5" # latest release tag
  for_each = { for idx, val in concat(module.rds_mysql, module.rds_mssql) : idx => val }

  sonar_version    = module.globals.tarball_location.version
  usc_access_token = module.hub[0].access_tokens.usc.token
  hub_info = {
    hub_ip_address           = module.hub[0].public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub[0].ssh_user
  }

  assignee_gw   = module.agentless_gw_group[0].jsonar_uid
  assignee_role = module.agentless_gw_group[0].iam_role
  database_details = {
    db_username   = each.value.db_username
    db_password   = each.value.db_password
    db_arn        = each.value.db_arn
    db_port       = each.value.db_port
    db_identifier = each.value.db_identifier
    db_address    = each.value.db_address
    db_engine     = each.value.db_engine
    db_name       = try(each.value.db_name, null)
  }
  tags = local.tags
  depends_on = [
    module.federation,
    module.rds_mysql,
    module.rds_mssql
  ]
}
