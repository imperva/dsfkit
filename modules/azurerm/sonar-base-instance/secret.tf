#################################
# Generating a key pair for remote Agentless Gateway federation, HADR, etc.
#################################

resource "tls_private_key" "sonarw_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  primary_node_sonarw_public_key  = !var.hadr_secondary_node ? "${chomp(tls_private_key.sonarw_private_key.public_key_openssh)} produced-by-terraform" : var.sonarw_public_key
  primary_node_sonarw_private_key = !var.hadr_secondary_node ? chomp(tls_private_key.sonarw_private_key.private_key_pem) : var.sonarw_private_key
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  # tbd: change this discussting hash. The problem is that the vault name must be up to ~24 chars
  name = "a${substr(md5(join("-", [var.name, "vault"])), 0, 10)}"
  # name                       = join("-", [var.friendly_name, "vault"])
  location                   = var.resource_group.location
  resource_group_name        = var.resource_group.name
  enabled_for_deployment     = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

resource "azurerm_key_vault_access_policy" "vault_owner_access_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "vault_vm_access_policy" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.dsf_base_instance.identity[0].principal_id

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]
}

resource "azurerm_key_vault_secret" "sonarw_private_key_secret" {
  name         = join("-", [var.name, "sonarw", "private", "key"])
  value        = chomp(local.primary_node_sonarw_private_key)
  key_vault_id = azurerm_key_vault.vault.id
  content_type = "sonarw ssh private key"
  depends_on = [
    azurerm_key_vault_access_policy.vault_owner_access_policy
  ]
}
