locals {
  db_types_for_agentless = local.agentless_gw_count > 0 ? var.simulation_db_types_for_agentless : []
}

module "mssql" {
  source = "../../../../modules/azurerm/mssql-db"
  count   = contains(local.db_types_for_agentless, "MsSQL") ? 1 : 0
  resource_group = local.resource_group
  # security_group_ingress_cidrs = local.workstation_cidr

  tags = local.tags
}

module "db_onboarding1" {
  source = "../../../../modules/azurerm/poc-db-onboarder"
  for_each = { for idx, val in concat(module.mssql) : idx => val }

  resource_group = local.resource_group
  sonar_version    = var.sonar_version
  usc_access_token = nonsensitive(module.hub_main[0].access_tokens.usc.token)
  hub_info = {
    hub_ip_address           = module.hub_main[0].public_ip
    hub_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    hub_ssh_user             = module.hub_main[0].ssh_user
  }

  assignee_gw   = module.hub_main[0].jsonar_uid
  assignee_role = module.hub_main[0].principal_id

  database_details = {
    db_username   = each.value.db_username
    db_password   = each.value.db_password
    db_id         = each.value.db_id
    db_port       = each.value.db_port
    db_identifier = each.value.db_identifier
    db_address    = each.value.db_address
    db_engine     = each.value.db_engine
    db_name       = each.value.db_name
  }
  tags = local.tags
  depends_on = [
    module.federation,
    module.mssql
  ]
}
