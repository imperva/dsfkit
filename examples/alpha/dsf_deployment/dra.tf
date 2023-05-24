locals {
  dra_analytics_server_count = var.enable_dsf_dra ? var.dra_analytics_server_count : 0
}

module "dra_admin" {
  source = "../../../modules/aws/dra/dra-admin"
  count  = var.enable_dsf_dra ? 1 : 0

  friendly_name                  = join("-", [local.deployment_name_salted, "admin"])
  subnet_id                      = local.dra_admin_subnet_id
  dra_version                    = var.dra_version
  ebs                            = var.dra_admin_ebs_details
  admin_registration_password    = local.password
  admin_password                 = local.password
  allowed_web_console_cidrs      = local.workstation_cidr
  allowed_analytics_server_cidrs = [data.aws_subnet.dra_analytics.cidr_block]
  allowed_ssh_cidrs              = local.workstation_cidr
  attach_persistent_public_ip    = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "analytics_server_group" {
  source = "../../../modules/aws/dra/dra-analytics"

  count                       = local.dra_analytics_server_count
  friendly_name               = join("-", [local.deployment_name_salted, "analytics", "server", count.index])
  subnet_id                   = local.dra_analytics_subnet_id
  dra_version                 = var.dra_version
  ebs                         = var.dra_analytics_group_ebs_details
  admin_registration_password = local.password
  admin_password              = local.password
  allowed_admin_server_cidrs  = [data.aws_subnet.dra_admin.cidr_block]
  allowed_ssh_cidrs           = concat(var.workstation_cidr, [data.aws_subnet.dra_admin.cidr_block])
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  archiver_password       = local.password
  admin_server_private_ip = module.dra_admin[0].private_ip
  admin_server_public_ip  = module.dra_admin[0].public_ip
  tags                    = local.tags
  depends_on = [
    module.vpc
  ]
}
