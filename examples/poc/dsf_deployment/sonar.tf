locals {
  database_cidr      = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location   = module.globals.tarball_location
  agentless_gw_count = var.enable_dsf_hub ? var.agentless_gw_count : 0
}

module "hub" {
  source  = "imperva/dsf-hub/aws"
  version = "1.4.5" # latest release tag
  count   = var.enable_dsf_hub ? 1 : 0

  friendly_name                = join("-", [local.deployment_name_salted, "hub"])
  subnet_id                    = local.hub_subnet_id
  binaries_location            = local.tarball_location
  web_console_admin_password   = local.password
  ebs                          = var.hub_ebs_details
  attach_persistent_public_ip  = true
  use_public_ip                = true
  should_generate_access_token = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_agentless_gw_cidrs        = [data.aws_subnet.agentless_gw.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  tags                              = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_group" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.4.5" # latest release tag
  count   = local.agentless_gw_count

  friendly_name              = join("-", [local.deployment_name_salted, "agentless", "gw", count.index])
  subnet_id                  = local.agentless_gw_subnet_id
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.password
  hub_sonarw_public_key      = module.hub[0].sonarw_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_hub_cidrs = [data.aws_subnet.hub.cidr_block]
  allowed_all_cidrs = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc,
  ]
}

module "federation" {
  source   = "imperva/dsf-federation/null"
  version  = "1.4.5" # latest release tag
  for_each = { for idx, val in module.agentless_gw_group : idx => val }

  gw_info = {
    gw_ip_address           = each.value.private_ip
    gw_private_ssh_key_path = module.key_pair.private_key_file_path
    gw_ssh_user             = each.value.ssh_user
  }
  hub_info = {
    hub_ip_address           = module.hub[0].public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = module.hub[0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  depends_on = [
    module.hub,
    module.agentless_gw_group,
  ]
}
