locals {
  dra_analytics_count = var.enable_dra ? var.dra_analytics_count : 0

  dra_admin_public_ip = var.enable_dra ? [format("%s/32", module.dra_admin[0].public_ip)] : []
  dra_admin_cidr_list = concat(module.network[0].vnet_address_space, local.dra_admin_public_ip)

  dra_admin_image_exits     = var.dra_admin_image_details != null ? true : false
  dra_admin_vhd_exits       = var.dra_admin_vhd_details != null ? true : false
  dra_analytics_image_exits = var.dra_analytics_image_details != null ? true : false
  dra_analytics_vhd_exits   = var.dra_analytics_vhd_details != null ? true : false
}

module "dra_admin" {
  source  = "imperva/dsf-dra-admin/azurerm"
  version = "1.7.25" # latest release tag
  count   = var.enable_dra ? 1 : 0

  name                        = join("-", [local.deployment_name_salted, "dra", "admin"])
  subnet_id                   = module.network[0].vnet_subnets[0]
  resource_group              = local.resource_group
  storage_details             = var.dra_admin_storage_details
  ssh_public_key              = tls_private_key.ssh_key.public_key_openssh
  admin_registration_password = local.password
  admin_ssh_password          = local.password

  allowed_web_console_cidrs = var.web_console_cidr
  allowed_analytics_cidrs   = module.network[0].vnet_address_space
  allowed_hub_cidrs         = local.hub_cidr_list
  allowed_ssh_cidrs         = concat(local.workstation_cidr, var.allowed_ssh_cidrs)

  image_vhd_details = {
    image = local.dra_admin_image_exits ? {
      resource_group_name = var.dra_admin_image_details.resource_group_name
      image_id            = var.dra_admin_image_details.image_id
    } : null,
    vhd = local.dra_admin_vhd_exits ? {
      path_to_vhd          = var.dra_admin_vhd_details.path_to_vhd
      storage_account_name = var.dra_admin_vhd_details.storage_account_name
      container_name       = var.dra_admin_vhd_details.container_name
    } : null
  }

  attach_persistent_public_ip = true
  tags                        = local.tags

  depends_on = [
    module.network
  ]
}

module "dra_analytics" {
  source  = "imperva/dsf-dra-analytics/azurerm"
  version = "1.7.25" # latest release tag
  count   = local.dra_analytics_count

  name                        = join("-", [local.deployment_name_salted, "dra", "analytics", count.index])
  subnet_id                   = module.network[0].vnet_subnets[1]
  resource_group              = local.resource_group
  storage_details             = var.dra_analytics_storage_details
  ssh_public_key              = tls_private_key.ssh_key.public_key_openssh
  admin_registration_password = local.password
  analytics_ssh_password      = local.password
  archiver_password           = local.password

  allowed_admin_cidrs = module.network[0].vnet_address_space
  allowed_ssh_cidrs   = concat(local.workstation_cidr, local.hub_cidr_list)
  #allowed_ssh_cidrs = concat(var.allowed_ssh_cidrs, local.hub_cidr_list, local.workstation_cidr)

  admin_server_private_ip = module.dra_admin[0].private_ip
  admin_server_public_ip  = module.dra_admin[0].public_ip

  image_vhd_details = {
    image = local.dra_analytics_image_exits ? {
      resource_group_name = var.dra_analytics_image_details.resource_group_name
      image_id            = var.dra_analytics_image_details.image_id
    } : null,
    vhd = local.dra_analytics_vhd_exits ? {
      path_to_vhd          = var.dra_analytics_vhd_details.path_to_vhd
      storage_account_name = var.dra_analytics_vhd_details.storage_account_name
      container_name       = var.dra_analytics_vhd_details.container_name
    } : null
  }
  tags = local.tags

  depends_on = [
    module.network
  ]
}