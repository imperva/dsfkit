#################################
# Generating ssh federation keys
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

# tbd: rename all example resources
resource "azurerm_key_vault" "example" {
  # tbd: change this discussting hash. The problem is that the vault name must be up to ~24 chars
  name = "a${substr(md5(join("-", [var.name, "vault"])), 0, 10)}"
  # name                       = join("-", [var.friendly_name, "vault"])
  location                   = var.resource_group.location
  resource_group_name        = var.resource_group.name
  enabled_for_deployment     = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  # public_network_access_enabled = false
  sku_name = "standard"

}

resource "azurerm_key_vault_access_policy" "example1" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  # tbd: move to key (not secret). and make sure we only keep the relevant permissions
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

# tbd: rename all "example" resourcs
# tbd: reduce this secret permissions
resource "azurerm_key_vault_access_policy" "example2" {
  key_vault_id = azurerm_key_vault.example.id
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

resource "azurerm_key_vault_secret" "dsf_hub_federation_private_key" {
  name         = join("-", [var.name, "sonarw", "private", "key"])
  value        = chomp(local.primary_node_sonarw_private_key)
  key_vault_id = azurerm_key_vault.example.id
  content_type = "sonarw ssh private key"
  # tbd: try to avoid this dependency
  depends_on = [
    azurerm_key_vault_access_policy.example1
  ]
}

# tbd: move to key instead of secret