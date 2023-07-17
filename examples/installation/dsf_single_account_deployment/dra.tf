locals {
  dra_analytics_server_count = var.enable_dra ? var.dra_analytics_server_count : 0

  dra_admin_cidr_list = [data.aws_subnet.dra_admin.cidr_block]
}

module "dra_admin" {
  source  = "../../../modules/aws/dra-admin"
  count   = var.enable_dra ? 1 : 0

  friendly_name                  = join("-", [local.deployment_name_salted, "dra", "admin"])
  subnet_id                      = var.subnet_ids.dra_admin_subnet_id
  security_group_ids             = var.security_group_ids_dra_admin
  dra_version                    = module.globals.dra_version
  ebs                            = var.dra_admin_ebs_details
  admin_registration_password    = local.password
  admin_password                 = local.password
  allowed_web_console_cidrs      = var.web_console_cidr
  allowed_analytics_server_cidrs = [data.aws_subnet.dra_analytics.cidr_block]
  allowed_hub_cidrs              = local.hub_cidr_list
  allowed_ssh_cidrs              = local.workstation_cidr
  attach_persistent_public_ip    = true
  key_pair                       = local.dra_admin_public_key_name
  instance_profile_name          = var.dra_admin_instance_profile_name
  tags                           = local.tags
}

module "analytics_server_group" {
  source  = "../../../modules/aws/dra-analytics"
  count                       = local.dra_analytics_server_count

  friendly_name               = join("-", [local.deployment_name_salted, "dra", "analytics", "server", count.index])
  subnet_id                   = var.subnet_ids.dra_analytics_subnet_id
  security_group_ids          = var.security_group_ids_dra_analytics
  dra_version                 = module.globals.dra_version
  ebs                         = var.dra_analytics_ebs_details
  admin_registration_password = local.password
  admin_password              = local.password
  allowed_admin_server_cidrs  = [data.aws_subnet.dra_admin.cidr_block]
  allowed_gateways_cidrs      = distinct(concat(local.agent_gw_cidr_list, local.agentless_gw_cidr_list))
  allowed_ssh_cidrs           = local.hub_cidr_list
  key_pair                    = local.dra_analytics_public_key_name
  instance_profile_name       = var.dra_analytics_instance_profile_name
  archiver_password           = local.password
  admin_server_private_ip     = module.dra_admin[0].private_ip
  admin_server_public_ip      = module.dra_admin[0].public_ip
  tags                        = local.tags
  providers = {
    aws = aws.provider-2
  }
}
