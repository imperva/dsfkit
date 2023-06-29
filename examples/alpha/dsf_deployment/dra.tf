locals {
  dra_analytics_server_count = var.enable_dra ? var.dra_analytics_server_count : 0

  dra_admin_cidr_list = compact([data.aws_subnet.dra_admin.cidr_block, try(format("%s/32", module.dra_admin[0].public_ip), null)])
}

module "dra_admin" {
  source  = "imperva/dsf-dra-admin/aws"
  version = "1.4.8" # latest release tag
  count   = var.enable_dra ? 1 : 0

  friendly_name                  = join("-", [local.deployment_name_salted, "dra", "admin"])
  subnet_id                      = local.dra_admin_subnet_id
  dra_version                    = module.globals.dra_version
  ebs                            = var.dra_admin_ebs_details
  admin_registration_password    = local.password
  admin_password                 = local.password
  allowed_web_console_cidrs      = local.workstation_cidr
  allowed_analytics_server_cidrs = [data.aws_subnet.dra_analytics.cidr_block]
  allowed_hub_cidrs              = local.hub_cidr_list
  attach_persistent_public_ip    = true
  key_pair                       = module.key_pair.key_pair.key_pair_name
  tags                           = local.tags
  depends_on = [
    module.vpc
  ]
}

module "analytics_server_group" {
  source  = "imperva/dsf-dra-analytics/aws"
  version = "1.4.8" # latest release tag

  count                       = local.dra_analytics_server_count
  friendly_name               = join("-", [local.deployment_name_salted, "dra", "analytics", "server", count.index])
  subnet_id                   = local.dra_analytics_subnet_id
  dra_version                 = module.globals.dra_version
  ebs                         = var.dra_analytics_group_ebs_details
  admin_registration_password = local.password
  admin_password              = local.password
  allowed_admin_server_cidrs  = [data.aws_subnet.dra_admin.cidr_block]
  allowed_gateways_cidrs      = distinct(concat(local.agent_gw_cidr_list, local.agentless_gw_cidr_list))
  key_pair                    = module.key_pair.key_pair.key_pair_name
  archiver_password           = local.password
  admin_server_private_ip     = module.dra_admin[0].private_ip
  admin_server_public_ip      = module.dra_admin[0].public_ip
  tags                        = local.tags
  depends_on = [
    module.vpc
  ]
}
