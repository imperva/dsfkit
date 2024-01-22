resource "random_password" "db_password" {
  length  = 15
  special = true
}

resource "random_pet" "db_id" {
}

locals {
  db_username   = "administrator"
  db_password   = random_password.db_password.result
  db_identifier = "edsf-db-demo-${random_pet.db_id.id}"
  db_address    = "${local.db_identifier}.database.windows.net"
}

locals {
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
  name                = join("-", [local.server_name, "allow-all"])
  server_id         = azurerm_mssql_server.server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_mssql_database" "db" {
  name        = local.database_name
  server_id   = azurerm_mssql_server.server.id
  sample_name = "AdventureWorksLT"
  tags        = var.tags
}

resource "azurerm_mssql_server_extended_auditing_policy" "example" {
  server_id                               = azurerm_mssql_server.server.id
  storage_endpoint                        = azurerm_storage_account.example.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.example.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 30
}

resource "azurerm_eventhub_namespace" "example" {
  name                = local.eventhub_ns_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_eventhub" "example" {
  name                = local.eventhub_name
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = var.resource_group.name

  partition_count   = 2
  message_retention = 1
}

data "azurerm_eventhub_namespace_authorization_rule" "example" {
  name                = "RootManageSharedAccessKey"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = var.resource_group.name
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                           = "example-diagnotic-setting"
  target_resource_id             = "${azurerm_mssql_server.server.id}/databases/master"
  eventhub_authorization_rule_id = data.azurerm_eventhub_namespace_authorization_rule.example.id
  eventhub_name                  = azurerm_eventhub.example.name
  # log_analytics_workspace_id     = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "SQLSecurityAuditEvents"
    # azurerm_storage_management_policy = azurerm_storage_management_policy.example.id
  }

  metric {
    category = "AllMetrics"
  }
  depends_on = [ azurerm_mssql_database.db ]
}

resource "azurerm_storage_account" "example" {
  name                = join("-", [local.db_identifier, "storage"])
  resource_group_name          = var.resource_group.name
  location                     = var.resource_group.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  allow_nested_items_to_be_public = false

#   network_rules {
#     default_action             = "Deny"
#     ip_rules                   = ["127.0.0.1"]
#     virtual_network_subnet_ids = [azurerm_subnet.example.id]
#     bypass                     = ["AzureServices"]
#   }

  identity {
    type = "SystemAssigned"
  }
}
