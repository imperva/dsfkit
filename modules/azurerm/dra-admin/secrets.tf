data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                       = trim(substr(var.name, -24, -1), "-")
  location                   = var.resource_group.location
  resource_group_name        = var.resource_group.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enabled_for_deployment     = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = var.tags
}

resource "azurerm_key_vault_access_policy" "vault_owner_access_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = [
    "Delete",
    "Get",
    "Purge",
    "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "vault_vm_access_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.user_assigned_identity.principal_id

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_secret" "admin_analytics_registration_password" {
  name         = join("-", [var.name, "admin", "analytics", "registration", "password"])
  value        = var.admin_registration_password
  key_vault_id = azurerm_key_vault.vault.id
  content_type = "DRA admin registration password"
  tags         = var.tags
  depends_on = [
    azurerm_key_vault_access_policy.vault_owner_access_policy
  ]
}

resource "azurerm_key_vault_secret" "ssh_password" {
  name         = join("-", [var.name, "admin", "ssh", "password"])
  value        = var.admin_ssh_password
  key_vault_id = azurerm_key_vault.vault.id
  content_type = "DRA Admin ssh password"
  tags         = var.tags
  depends_on = [
    azurerm_key_vault_access_policy.vault_owner_access_policy
  ]
}