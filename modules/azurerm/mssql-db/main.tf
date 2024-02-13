resource "random_password" "db_password" {
  length  = 15
  special = true
}

resource "random_pet" "db_id" {}

locals {
  db_username      = var.username
  db_password      = length(var.password) > 0 ? var.password : random_password.db_password.result
  db_identifier    = length(var.identifier) > 0 ? var.identifier : join("-", [var.name_prefix, random_pet.db_id.id])
  db_address       = "${local.db_identifier}.database.windows.net"
  server_name      = local.db_identifier
  database_name    = local.db_identifier
  eventhub_ns_name = local.db_identifier
  eventhub_name    = local.db_identifier
}

resource "azurerm_mssql_server" "server" {
  name                         = local.server_name
  resource_group_name          = var.resource_group.name
  location                     = var.resource_group.location
  version                      = "12.0"
  administrator_login          = local.db_username
  administrator_login_password = local.db_password
  minimum_tls_version          = "1.2"

  tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "allow_inbound" {
  count = length(var.security_group_ingress_cidrs)

  name             = join("-", [local.server_name, count.index])
  server_id        = azurerm_mssql_server.server.id
  start_ip_address = cidrhost(var.security_group_ingress_cidrs[count.index], 0)
  end_ip_address   = cidrhost(var.security_group_ingress_cidrs[count.index], -1)
}

resource "azurerm_mssql_database" "db" {
  name        = local.database_name
  server_id   = azurerm_mssql_server.server.id
  sample_name = "AdventureWorksLT"
  tags        = var.tags
}

data "azurerm_subscription" "current" {}

resource "azurerm_mssql_server_extended_auditing_policy" "policy" {
  server_id                               = azurerm_mssql_server.server.id
  storage_endpoint                        = azurerm_storage_account.sa.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.sa.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 0

  enabled                = true
  log_monitoring_enabled = true

  storage_account_subscription_id = data.azurerm_subscription.current.subscription_id
}

resource "azurerm_eventhub_namespace" "ns" {
  name                = local.eventhub_ns_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_eventhub" "eventhub" {
  name                = local.eventhub_name
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = var.resource_group.name

  partition_count   = 2
  message_retention = 1
}

data "azurerm_eventhub_namespace_authorization_rule" "auth_rule" {
  name                = "RootManageSharedAccessKey"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = var.resource_group.name
}

resource "azurerm_monitor_diagnostic_setting" "settings" {
  name               = "sonar_diagnostic_settings"
  target_resource_id = "${azurerm_mssql_database.db.server_id}/databases/master" # creates an expilicit dependency on the database

  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.auth_rule.id
  eventhub_name                  = azurerm_eventhub.eventhub.name

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
}

resource "azurerm_storage_account" "sa" {
  name                = "sonar${replace(random_pet.db_id.id, "-", "")}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  allow_nested_items_to_be_public = false

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
