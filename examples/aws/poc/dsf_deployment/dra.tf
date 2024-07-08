locals {
  dra_analytics_count = var.enable_dra ? var.dra_analytics_count : 0

  dra_admin_cidr_list = concat([data.aws_subnet.dra_admin.cidr_block], var.enable_dra ? [format("%s/32", module.dra_admin[0].public_ip)] : [])
}

module "dra_admin" {
  source  = "imperva/dsf-dra-admin/aws"
  version = "1.7.16" # latest release tag
  count   = var.enable_dra ? 1 : 0

  name                        = join("-", [local.deployment_name_salted, "dra", "admin"])
  subnet_id                   = local.dra_admin_subnet_id
  dra_version                 = module.globals.dra_version
  ebs                         = var.dra_admin_ebs_details
  key_pair                    = module.key_pair.key_pair.key_pair_name
  admin_registration_password = local.password
  admin_ssh_password          = local.password
  allowed_web_console_cidrs   = var.web_console_cidr
  allowed_analytics_cidrs     = [data.aws_subnet.dra_analytics.cidr_block]
  allowed_hub_cidrs           = local.hub_cidr_list
  allowed_ssh_cidrs           = concat(local.workstation_cidr, var.allowed_ssh_cidrs)
  attach_persistent_public_ip = true

  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "dra_analytics" {
  source  = "imperva/dsf-dra-analytics/aws"
  version = "1.7.16" # latest release tag

  count                       = local.dra_analytics_count
  name                        = join("-", [local.deployment_name_salted, "dra", "analytics", count.index])
  subnet_id                   = local.dra_analytics_subnet_id
  dra_version                 = module.globals.dra_version
  ebs                         = var.dra_analytics_ebs_details
  admin_registration_password = local.password
  analytics_ssh_password      = local.password
  allowed_admin_cidrs         = [data.aws_subnet.dra_admin.cidr_block]
  allowed_ssh_cidrs           = concat(local.hub_cidr_list, var.allowed_ssh_cidrs)
  key_pair                    = module.key_pair.key_pair.key_pair_name
  archiver_password           = local.password
  admin_server_private_ip     = module.dra_admin[0].private_ip
  admin_server_public_ip      = module.dra_admin[0].public_ip
  tags                        = local.tags
  depends_on = [
    module.vpc
  ]
}
