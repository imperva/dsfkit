provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "globals" {
  # source        = "imperva/dsf-globals/aws"
  # version       = "1.3.5" # latest release tag
  source        = "../../../modules/azurerm/core/globals"
  sonar_version = var.sonar_version
}

locals {
  deployment_name_salted = join("-", [var.deployment_name, module.globals.salt])
}

locals {
  workstation_cidr_24        = [format("%s.0/24", regex("\\d*\\.\\d*\\.\\d*", module.globals.my_ip))]
  web_console_admin_password = var.web_console_admin_password != null ? var.web_console_admin_password : module.globals.random_password
  workstation_cidr           = var.workstation_cidr != null ? var.workstation_cidr : local.workstation_cidr_24
  # database_cidr              = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location = module.globals.tarball_location
  tags = merge(module.globals.tags, { "deployment_name" = local.deployment_name_salted })
  resource_group = {
    location = azurerm_resource_group.rg.location
    name     = azurerm_resource_group.rg.name
  }
}

resource "azurerm_resource_group" "rg" {
  name     = local.deployment_name_salted
  location = var.location
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

# network
module "network" {
  source              = "Azure/network/azurerm"
  vnet_name           = "${local.deployment_name_salted}-${module.globals.current_user_name}"
  resource_group_name = azurerm_resource_group.rg.name
  address_spaces      = [var.network_ip_range]
  subnet_prefixes     = var.private_subnets
  subnet_names        = formatlist("subnet-%d", range(length(var.private_subnets)))

  use_for_each = true
  tags         = local.tags
  depends_on = [
    azurerm_resource_group.rg
  ]
}

##############################
# Generating deployment
##############################
module "hub" {
  # count  = 0
  source = "../../../modules/azurerm/hub"
  # version                             = "1.3.5" # latest release tag

  friendly_name              = join("-", [local.deployment_name_salted, "hub", "main"])
  resource_group             = local.resource_group
  subnet_id                  = module.network.vnet_subnets[0]
  binaries_location          = local.tarball_location
  password                   = local.web_console_admin_password
  storage_details            = var.hub_managed_disk_details

  allowed_all_cidrs = ["82.166.106.0/24"]
  attach_persistent_public_ip = true

  ssh_key_pair = {
    ssh_public_key =  tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  use_public_ip = true

  depends_on = [
    azurerm_resource_group.rg,
    module.network
  ]
}

# ##############################
# # Generating deployment
# ##############################

# module "agentless_gw_group" {
#   count  = var.gw_count
#   source = "../../../modules/azurerm/agentless-gw"
#   # version                             = "1.3.5" # latest release tag

  friendly_name                       = join("-", [local.deployment_name_salted, "gw", count.index, "main"])
#   friendly_name                       = join("-", [var.deployment_name, "gw", count.index])
#   resource_group                      = local.resource_group
#   subnet_id                           = module.network.vnet_subnets[0]
#   storage_details                     = var.hub_managed_disk_details
#   binaries_location                   = local.tarball_location
#   web_console_admin_password          = local.web_console_admin_password
#   hub_sonarw_public_key               = module.hub.sonarw_public_key
#   create_and_attach_public_elastic_ip = false
#   # create_and_attach_public_elastic_ip = true
#   ssh_key = {
#     ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
#     ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
#   }
#   ingress_communication = {
#     full_access_cidr_list = concat(local.workstation_cidr, ["${module.hub.private_ip}/32"])
#     use_public_ip         = false
#     # use_public_ip         = true
#   }
#   ingress_communication_via_proxy = {
#     proxy_address              = module.hub.public_ip
#     proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
#     proxy_ssh_user             = module.hub.ssh_user
#   }
#   depends_on = [
#     module.network
#   ]
# }

# module "federation" {
#   for_each = { for idx, val in module.agentless_gw_group : idx => val }
#   source   = "imperva/dsf-federation/null"
#   gw_info = {
#     gw_ip_address = each.value.private_ip
#     # gw_ip_address           = each.value.public_ip
#     gw_private_ssh_key_path = local_sensitive_file.ssh_key.filename
#     gw_ssh_user             = each.value.ssh_user
#   }
#   hub_info = {
#     hub_ip_address           = module.hub.public_ip
#     hub_private_ssh_key_path = local_sensitive_file.ssh_key.filename
#     hub_ssh_user             = module.hub.ssh_user
#   }
#   gw_proxy_info = {
#     proxy_address              = module.hub.public_ip
#     proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
#     proxy_ssh_user             = module.hub.ssh_user
#   }
#   depends_on = [
#     module.hub,
#     module.agentless_gw_group,
#   ]
# }
