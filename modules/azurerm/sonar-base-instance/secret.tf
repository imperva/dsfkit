#################################
# Generating a key pair for remote Agentless Gateway federation, HADR, etc.
#################################

resource "tls_private_key" "sonarw_private_key" {
  count     = var.sonarw_private_key_secret_name == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  primary_node_sonarw_public_key  = var.sonarw_public_key_content != null ? var.sonarw_public_key_content : (!var.hadr_secondary_node ? "${chomp(tls_private_key.sonarw_private_key[0].public_key_openssh)} produced-by-terraform" : var.primary_node_sonarw_public_key)
  primary_node_sonarw_private_key = var.sonarw_private_key_secret_name != null ? var.sonarw_private_key_secret_name : (!var.hadr_secondary_node ? chomp(tls_private_key.sonarw_private_key[0].private_key_pem) : var.primary_node_sonarw_private_key)
#  password_secret_aws_arn = var.password_secret_name == null ? aws_secretsmanager_secret.password_secret[0].arn : data.aws_secretsmanager_secret.password_secret_data[0].arn
  password_secret_name    = azurerm_key_vault_secret.password_key_secret.name
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                       = var.name
  location                   = var.resource_group.location
  resource_group_name        = var.resource_group.name
  enabled_for_deployment     = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"

  tags = {
    "name" = join("-", [var.name, "vault"])
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
    "Get",
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

resource "azurerm_key_vault_secret" "password_key_secret" {
  name         = join("-", [var.name, "password"])
  value        = chomp(var.password)
  key_vault_id = azurerm_key_vault.vault.id
  content_type = "password"
  depends_on = [
    azurerm_key_vault_access_policy.vault_owner_access_policy
  ]
}

resource "azurerm_key_vault_secret" "access_tokens" {
  count       = length(local.access_tokens)
  name         = join("-", [var.name, local.access_tokens[count.index].name, "access", "token"])
  value        = random_uuid.access_tokens[count.index].result
  key_vault_id = azurerm_key_vault.vault.id
  content_type = "access token"
  depends_on = [
    azurerm_key_vault_access_policy.vault_owner_access_policy
  ]
}

# resource "azurerm_key_vault_access_policy" "vault_vm_access_policy" {
#   key_vault_id = azurerm_key_vault.vault.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = azurerm_linux_virtual_machine.dsf_base_instance.identity[0].principal_id

#   key_permissions = [
#     "Decrypt"
#   ]
# }

# resource "azurerm_key_vault_key" "key" {
#   name         = join("-", [var.name, "enc", "key"])
#   key_vault_id = azurerm_key_vault.vault.id
#   key_type     = "RSA"
#   key_size     = 4096
#   key_opts = [
#     "decrypt",
#     "encrypt",
#   ]
#   tags = var.tags
#   depends_on = [
#     azurerm_key_vault_access_policy.vault_owner_access_policy
#   ]
# }

# resource "local_sensitive_file" "foo" {
#   content  = chomp(local.primary_node_sonarw_private_key)
#   filename = "foo.bar"
# }

# locals {
#   secrets = {
#     "password" = var.password
#     "sonarw_private_key_secret" = chomp(local.primary_node_sonarw_private_key)
#   }
#   _secrets = { for k,v in local.secrets: k => {
#     plain_text = v
#     cipher_text = data.azurerm_key_vault_encrypted_value.encrypted_string[k].encrypted_data
#   }}
# }

# output "sdf" {
#   value = local._secrets
# }

# data "azurerm_key_vault_encrypted_value" "encrypted_string" {
#   for_each = local.secrets
#   key_vault_key_id       = azurerm_key_vault_key.key.id
#   plain_text_value         = base64encode(each.value)
#   algorithm        = local.encryption_algorithm
# }

# # resource "azurerm_key_vault_secret" "sonarw_private_key_secret" {
# #   name         = join("-", [var.name, "sonarw", "private", "key"])
# #   value        = chomp(local.primary_node_sonarw_private_key)
# #   key_vault_id = azurerm_key_vault.vault.id
# #   content_type = "sonarw ssh private key"
# #   depends_on = [
# #     azurerm_key_vault_access_policy.vault_owner_access_policy
# #   ]
# # }
