module "globals" {
  source  = "../../../../modules/azurerm/core/globals"
}

resource "azurerm_resource_group" "rg" {
  count    = var.resource_group == null ? 1 : 0
  name     = "${local.deployment_name_salted}-${module.globals.current_user_name}"
  location = var.resource_group_location
}

data "azurerm_resource_group" "rg" {
  count = var.resource_group != null ? 1 : 0
  name  = var.resource_group
}

# create key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ssh_key" {
  filename = "ssh_keys/dsf_ssh_key-${terraform.workspace}"
  content  = tls_private_key.ssh_key.private_key_openssh
}

locals {
  workstation_cidr_24    = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
  password               = var.password != null ? var.password : module.globals.random_password
  workstation_cidr       = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  tags                   = merge(module.globals.tags, var.tags, { "deployment_name" = local.deployment_name_salted })
  private_key_file_path  = local_sensitive_file.ssh_key.filename
  resource_group = var.resource_group == null ? {
    location = azurerm_resource_group.rg[0].location
    name     = azurerm_resource_group.rg[0].name
    } : {
    location = data.azurerm_resource_group.rg[0].location
    name     = data.azurerm_resource_group.rg[0].name
  }
}
