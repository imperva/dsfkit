locals {
  dra_analytics_count = var.enable_sonar ? var.dra_analytics_count : 0

  dra_admin_subnet_id = var.subnet_ids != null ? var.subnet_ids.dra_admin_subnet_id : module.network[0].vnet_subnets[0]
}

module "dra_admin" {
  source = "../../../../modules/azurerm/dra-admin"
  count = var.enable_dra ? 1 : 0

  name = join("-", [local.deployment_name_salted, "dra", "admin"])
  resource_group = local.resource_group
  instance_size = var.dra_admin_instance_size
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
  image_details = var.dra_admin_image_details
  storage_details = var.dra_admin_storage_details
  admin_registration_password = local.password
  admin_password = local.password
  subnet_id = local.dra_admin_subnet_id

  allowed_web_console_cidrs = var.web_console_cidr
  allowed_analytics_cidrs = module.network[0].vnet_address_space
  allowed_hub_cidrs = module.network[0].vnet_address_space
  allowed_ssh_cidrs = local.workstation_cidr
#  allowed_ssh_cidrs = concat(local.workstation_cidr, var.allowed_ssh_cidrs)

  attach_persistent_public_ip = true

  tags = local.tags
}