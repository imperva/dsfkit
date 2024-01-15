locals {
  dra_analytics_count = var.enable_dra ? var.dra_analytics_count : 0

  dra_admin_public_ip = var.enable_dra ? [format("%s/32", module.dra_admin[0].public_ip)] : []
#  dra_admin_cidr_list = compact([module.network[0].vnet_address_space, local.dra_admin_public_ip])

#  dra_admin_subnet_id = var.subnet_ids != null ? var.subnet_ids.dra_admin_subnet_id : module.network[0].vnet_subnets[0]
#  dra_analytics_subnet_id = var.subnet_ids != null ? var.subnet_ids.dra_analytics_subnet_id : module.network[0].vnet_subnets[0]
}

module "dra_admin" {
  source = "../../../../modules/azurerm/dra-admin"
  count = var.enable_dra ? 1 : 0

  name = join("-", [local.deployment_name_salted, "dra", "admin"])
  subnet_id = module.network[0].vnet_subnets[0]
  resource_group = local.resource_group
  instance_size = var.dra_admin_instance_size
  storage_details = var.dra_admin_storage_details
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  image_details = var.dra_admin_image_details
  vhd_details = var.dra_admin_vhd_details
  admin_registration_password = local.password
  admin_ssh_password = local.password

  allowed_web_console_cidrs = var.web_console_cidr
  allowed_analytics_cidrs = module.network[0].vnet_address_space
  allowed_hub_cidrs = concat(module.network[0].vnet_address_space, [local.hub_public_ip])
#  allowed_hub_cidrs = module.network[0].vnet_address_space
#  allowed_hub_cidrs = local.hub_cidr_list
  allowed_ssh_cidrs = local.workstation_cidr

  attach_persistent_public_ip = true

  tags = local.tags

  depends_on = [
    module.network
  ]
}

module "dra_analytics" {
  source = "../../../../modules/azurerm/dra-analytics"
  count = local.dra_analytics_count

  name = join("-", [local.deployment_name_salted, "dra", "analytics", count.index])
  subnet_id = module.network[0].vnet_subnets[0]
  resource_group = local.resource_group
  instance_size = var.dra_analytics_instance_size
  storage_details = var.dra_analytics_storage_details
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  image_details = var.dra_analytics_image_details
  vhd_details = var.dra_analytics_vhd_details
  admin_registration_password = local.password
  analytics_ssh_password = local.password
  archiver_password = local.password

  allowed_admin_cidrs = module.network[0].vnet_address_space
  # todo - remove the workstation cidr from the allowed ssh cidrs
  allowed_ssh_cidrs = concat(local.workstation_cidr, module.network[0].vnet_address_space, [local.hub_public_ip])
#  allowed_ssh_cidrs = concat(local.workstation_cidr, local.hub_cidr_list)
  #  allowed_hub_cidrs = module.network[0].vnet_address_space
  #  allowed_ssh_cidrs = concat(local.workstation_cidr, var.allowed_ssh_cidrs)

  admin_server_private_ip = module.dra_admin[0].private_ip
  admin_server_public_ip = module.dra_admin[0].public_ip
  tags = local.tags

  depends_on = [
    module.network
  ]
}