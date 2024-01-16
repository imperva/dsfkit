###################################################################################
# Generating a key pair for remote Agentless Gateway federation, HADR, etc.
# A key pair is generated only for the HADR main nodes, and then "copied"
# to the HADR DR nodes.
# To do that, the public key is passed to the user data of the EC2 in clear text,
# but The private key is put in AWS secret manager, and the script of the EC2 user
# data fetches it from there.
# Currently we don't delete the private key from the secret manager once the
# deployment is completed, we may need it in the future.
# In addition, both the main and DR nodes put the same private key
# in the key manager under a different unique name. Consider optimizing in the
# future.
#
# TODO the private key is stored unencrypted in the TF state file - handle this
# See Security notice:
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
###################################################################################


resource "tls_private_key" "sonarw_private_key" {
  count     = var.sonarw_private_key_secret_name == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  main_node_sonarw_public_key  = var.sonarw_public_key_content != null ? var.sonarw_public_key_content : (!var.hadr_dr_node ? "${chomp(tls_private_key.sonarw_private_key[0].public_key_openssh)} produced-by-terraform" : var.main_node_sonarw_public_key)
  main_node_sonarw_private_key = var.sonarw_private_key_secret_name != null ? var.sonarw_private_key_secret_name : (!var.hadr_dr_node ? chomp(tls_private_key.sonarw_private_key[0].private_key_pem) : var.main_node_sonarw_private_key)
  password_secret_name         = azurerm_key_vault_secret.password_key_secret.name

  secret_names = [for v in azurerm_key_vault_secret.access_tokens : v.name]
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  # the vault name has quite a few restrictions:
  #   - alphanumeric only
  #   - 3 to 24 characters only
  #   - must start with a letter and end with a letter or number
  # for these reason, and to keep it from loosing uniqueness between different names,
  # we use a base64 hash of the server name to get the maximum entropy possible in 24 characters
  name                       = format("a%s", substr(replace(replace(replace(base64sha256(var.name), "+", ""), "/", ""), "=", ""), 0, 23))
  location                   = var.resource_group.location
  resource_group_name        = var.resource_group.name
  enabled_for_deployment     = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"

  tags = var.tags
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
  object_id    = azurerm_user_assigned_identity.dsf_base.principal_id

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_secret" "sonarw_private_key_secret" {
  # dots are somewhat common in server names, but aren't allowed in vault secrets
  name         = join("-", [replace(var.name, ".", "-"), "sonarw", "private", "key"])
  value        = chomp(local.main_node_sonarw_private_key)
  key_vault_id = azurerm_key_vault.vault.id
  content_type = "sonarw ssh private key"
  tags         = var.tags
  depends_on = [
    azurerm_key_vault_access_policy.vault_owner_access_policy
  ]
}

resource "azurerm_key_vault_secret" "password_key_secret" {
  # dots are somewhat common in server names, but aren't allowed in vault secrets
  name         = join("-", [replace(var.name, ".", "-"), "password"])
  value        = chomp(var.password)
  key_vault_id = azurerm_key_vault.vault.id
  content_type = "password"
  tags         = var.tags
  depends_on = [
    azurerm_key_vault_access_policy.vault_owner_access_policy
  ]
}

resource "azurerm_key_vault_secret" "access_tokens" {
  count        = length(local.access_tokens)
  # dots are somewhat common in server names, but aren't allowed in vault secrets
  name         = join("-", [replace(var.name, ".", "-"), local.access_tokens[count.index].name, "access", "token"])
  value        = random_uuid.access_tokens[count.index].result
  key_vault_id = azurerm_key_vault.vault.id
  content_type = "access token"
  tags         = var.tags
  depends_on = [
    azurerm_key_vault_access_policy.vault_owner_access_policy
  ]
}
