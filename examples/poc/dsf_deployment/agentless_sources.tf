locals {
  db_types_to_onboard = local.agentless_gw_count > 0 ? var.db_types_to_onboard : []
}

module "rds_mysql" {
  source  = "../../../modules/aws/rds-mysql-db"
  count   = contains(local.db_types_to_onboard, "RDS MySQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr
  tags                         = local.tags
}

module "rds_mssql" {
  source  = "../../../modules/aws/rds-mssql-db"
  count   = contains(local.db_types_to_onboard, "RDS MsSQL") ? 1 : 0

  rds_subnet_ids               = local.db_subnet_ids
  security_group_ingress_cidrs = local.workstation_cidr

  tags = local.tags
  providers = {
    aws                       = aws,
    aws.poc_scripts_s3_region = aws.poc_scripts_s3_region
  }
}

module "db_onboarding" {
  source   = "../../../modules/aws/poc-db-onboarder"
  for_each = { for idx, val in concat(module.rds_mysql, module.rds_mssql) : idx => val }

  sonar_version    = module.globals.tarball_location.version
  usc_access_token = module.hub[0].access_tokens.usc.token
  hub_info = {
    hub_ip_address           = module.hub[0].public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub[0].ssh_user
  }

  assignee_gw   = module.agentless_gw[0].jsonar_uid
  assignee_role = module.agentless_gw[0].iam_role
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
