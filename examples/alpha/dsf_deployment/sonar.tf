locals {
  database_cidr      = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location   = module.globals.tarball_location
  agentless_gw_count = var.enable_dsf_hub ? var.agentless_gw_count : 0

  hub_cidr_list          = compact([data.aws_subnet.hub.cidr_block, try(format("%s/32", module.hub[0].public_ip), null), try(format("%s/32", module.hub_secondary[0].public_ip), null)])
  agentless_gw_cidr_list = [data.aws_subnet.agentless_gw.cidr_block, data.aws_subnet.agentless_gw_secondary.cidr_block]
}

module "hub" {
  source  = "../../../modules/aws/hub"
  count   = var.enable_dsf_hub ? 1 : 0

  friendly_name               = join("-", [local.deployment_name_salted, "hub"])
  subnet_id                   = local.hub_subnet_id
  binaries_location           = local.tarball_location
  web_console_admin_password  = local.password
  ebs                         = var.hub_ebs_details
  attach_persistent_public_ip = true
  use_public_ip               = true
  generate_access_tokens      = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub_secondary.cidr_block]
  allowed_agentless_gw_cidrs        = local.agentless_gw_cidr_list
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = local.workstation_cidr
  mx_details = var.enable_dam ? [{
    name     = module.mx[0].display_name
    address  = coalesce(module.mx[0].public_ip, module.mx[0].private_ip)
    username = module.mx[0].web_console_user
    password = local.password
  }] : []
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_secondary" {
  source  = "../../../modules/aws/hub"
  count   = var.enable_dsf_hub && var.hub_hadr ? 1 : 0

  friendly_name               = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                   = local.hub_secondary_subnet_id
  binaries_location           = local.tarball_location
  web_console_admin_password  = local.password
  ebs                         = var.hub_ebs_details
  attach_persistent_public_ip = true
  use_public_ip               = true
  hadr_secondary_node         = true
  sonarw_public_key           = module.hub[0].sonarw_public_key
  sonarw_private_key          = module.hub[0].sonarw_private_key
  generate_access_tokens      = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub.cidr_block]
  allowed_agentless_gw_cidrs        = local.agentless_gw_cidr_list
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = local.workstation_cidr
  tags                              = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_hadr" {
  source  = "../../../modules/null/hadr"

  count = length(module.hub_secondary) > 0 ? 1 : 0

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.hub[0].public_ip
  dsf_primary_private_ip   = module.hub[0].private_ip
  dsf_secondary_ip         = module.hub_secondary[0].public_ip
  dsf_secondary_private_ip = module.hub_secondary[0].private_ip
  ssh_key_path             = module.key_pair.private_key_file_path
  ssh_user                 = module.hub[0].ssh_user
  depends_on = [
    module.hub,
    module.hub_secondary
  ]
}

module "agentless_gw_group" {
  source  = "../../../modules/aws/agentless-gw"
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
  allowed_agentless_gw_cidrs = [data.aws_subnet.agentless_gw_secondary.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.hub.cidr_block, data.aws_subnet.hub_secondary.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
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

module "agentless_gw_group_secondary" {
  source  = "../../../modules/aws/agentless-gw"
  count   = var.agentless_gw_hadr ? local.agentless_gw_count : 0

  friendly_name              = join("-", [local.deployment_name_salted, "agentless", "gw", "secondary", count.index])
  subnet_id                  = local.agentless_gw_secondary_subnet_id
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.password
  hub_sonarw_public_key      = module.hub[0].sonarw_public_key
  hadr_secondary_node        = true
  sonarw_public_key          = module.agentless_gw_group[count.index].sonarw_public_key
  sonarw_private_key         = module.agentless_gw_group[count.index].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.agentless_gw.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.hub.cidr_block, data.aws_subnet.hub_secondary.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
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

module "agentless_gw_group_hadr" {
  source  = "../../../modules/null/hadr"
  count   = length(module.agentless_gw_group_secondary)

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.agentless_gw_group[count.index].private_ip
  dsf_primary_private_ip   = module.agentless_gw_group[count.index].private_ip
  dsf_secondary_ip         = module.agentless_gw_group_secondary[count.index].private_ip
  dsf_secondary_private_ip = module.agentless_gw_group_secondary[count.index].private_ip
  ssh_key_path             = module.key_pair.private_key_file_path
  ssh_user                 = module.agentless_gw_group[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  depends_on = [
    module.agentless_gw_group,
    module.agentless_gw_group_secondary
  ]
}

locals {
  gws = merge(
    {for idx, val in module.agentless_gw_group : "agentless-gw-${idx}" => val},
    {for idx, val in module.agentless_gw_group_secondary : "agentless-gw-secondary-${idx}" => val},
  )
  gws_set = values(local.gws)
  hubs_set = concat(
    var.enable_dsf_hub ? [module.hub[0]] : [],
    var.enable_dsf_hub && var.hub_hadr ? [module.hub_secondary[0]] : []
  )
  hubs_keys = compact([
    var.enable_dsf_hub ? "hub-primary" : null,
    var.enable_dsf_hub && var.hub_hadr ? "hub-secondary" : null,
  ])

  hub_gw_combinations_values = setproduct(local.hubs_set, local.gws_set)
  hub_gw_combinations_keys = [for v in setproduct(local.hubs_keys, keys(local.gws)): "${v[0]}-${v[1]}"]

  hub_gw_combinations = zipmap(local.hub_gw_combinations_keys, local.hub_gw_combinations_values)
}

module "federation" {
  source = "../../../modules/null/federation"
  for_each = local.hub_gw_combinations

  gw_info = {
    gw_ip_address           = each.value[1].private_ip
    gw_private_ssh_key_path = module.key_pair.private_key_file_path
    gw_ssh_user             = each.value[1].ssh_user
  }
  hub_info = {
    hub_ip_address           = each.value[0].public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = each.value[0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_group_hadr
  ]
}
