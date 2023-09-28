locals {
  database_cidr      = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location   = var.tarball_location != null ? var.tarball_location : module.globals.tarball_location
  agentless_gw_count = var.enable_sonar ? var.agentless_gw_count : 0

  hub_public_ip          = var.enable_sonar ? (length(module.hub_main[0].public_ip) > 0 ? format("%s/32", module.hub_main[0].public_ip) : null) : null
  hub_dr_public_ip       = var.enable_sonar && var.hub_hadr ? (length(module.hub_dr[0].public_ip) > 0 ? format("%s/32", module.hub_dr[0].public_ip) : null) : null
  hub_cidr_list          = compact([data.aws_subnet.hub.cidr_block, data.aws_subnet.hub_dr.cidr_block, local.hub_public_ip, local.hub_dr_public_ip])
  agentless_gw_cidr_list = [data.aws_subnet.agentless_gw.cidr_block, data.aws_subnet.agentless_gw_dr.cidr_block]
}

module "hub_main" {
  source  = "imperva/dsf-hub/aws"
  version = "1.5.5" # latest release tag
  count   = var.enable_sonar ? 1 : 0

  friendly_name               = join("-", [local.deployment_name_salted, "hub", "main"])
  subnet_id                   = local.hub_subnet_id
  binaries_location           = local.tarball_location
  password                    = local.password
  ebs                         = var.hub_ebs_details
  instance_type               = var.hub_instance_type
  attach_persistent_public_ip = true
  use_public_ip               = true
  generate_access_tokens      = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub_dr.cidr_block]
  allowed_agentless_gw_cidrs        = local.agentless_gw_cidr_list
  allowed_dra_admin_cidrs           = local.dra_admin_cidr_list
  allowed_all_cidrs                 = local.workstation_cidr
  mx_details = var.enable_dam ? [for mx in module.mx : {
    name     = mx.display_name
    address  = coalesce(mx.public_dns, mx.private_dns)
    username = mx.web_console_user
    password = local.password
  }] : []
  dra_details = var.enable_dra? [for dra_admin in module.dra_admin : {
    name = dra_admin.display_name
    address = dra_admin.public_ip
    username = dra_admin.ssh_user
    password = local.password
  }] : []
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_dr" {
  source  = "imperva/dsf-hub/aws"
  version = "1.5.5" # latest release tag
  count   = var.enable_sonar && var.hub_hadr ? 1 : 0

  friendly_name                = join("-", [local.deployment_name_salted, "hub", "DR"])
  subnet_id                    = local.hub_dr_subnet_id
  binaries_location            = local.tarball_location
  password                     = local.password
  ebs                          = var.hub_ebs_details
  instance_type                = var.hub_instance_type
  attach_persistent_public_ip  = true
  use_public_ip                = true
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.hub_main[0].sonarw_public_key
  main_node_sonarw_private_key = module.hub_main[0].sonarw_private_key
  generate_access_tokens       = true
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
  source  = "imperva/dsf-hadr/null"
  version = "1.5.5" # latest release tag
  count   = length(module.hub_dr) > 0 ? 1 : 0

  sonar_version       = module.globals.tarball_location.version
  dsf_main_ip         = module.hub_main[0].public_ip
  dsf_main_private_ip = module.hub_main[0].private_ip
  dsf_dr_ip           = module.hub_dr[0].public_ip
  dsf_dr_private_ip   = module.hub_dr[0].private_ip
  ssh_key_path        = module.key_pair.private_key_file_path
  ssh_user            = module.hub_main[0].ssh_user
  depends_on = [
    module.hub_main,
    module.hub_dr
  ]
}

module "agentless_gw_main" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.5.5" # latest release tag
  count   = local.agentless_gw_count

  friendly_name         = join("-", [local.deployment_name_salted, "agentless", "gw", count.index, "main"])
  subnet_id             = local.agentless_gw_subnet_id
  ebs                   = var.agentless_gw_ebs_details
  instance_type         = var.agentless_gw_instance_type
  binaries_location     = local.tarball_location
  password              = local.password
  hub_sonarw_public_key = module.hub_main[0].sonarw_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.agentless_gw_dr.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.hub.cidr_block, data.aws_subnet.hub_dr.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "agentless_gw_dr" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.5.5" # latest release tag
  count   = var.agentless_gw_hadr ? local.agentless_gw_count : 0

  friendly_name                = join("-", [local.deployment_name_salted, "agentless", "gw", count.index, "DR"])
  subnet_id                    = local.agentless_gw_dr_subnet_id
  ebs                          = var.agentless_gw_ebs_details
  instance_type                = var.agentless_gw_instance_type
  binaries_location            = local.tarball_location
  password                     = local.password
  hub_sonarw_public_key        = module.hub_main[0].sonarw_public_key
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.agentless_gw_main[count.index].sonarw_public_key
  main_node_sonarw_private_key = module.agentless_gw_main[count.index].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.agentless_gw.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.hub.cidr_block, data.aws_subnet.hub_dr.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc,
  ]
}

module "agentless_gw_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.5.5" # latest release tag
  count   = length(module.agentless_gw_dr)

  sonar_version       = module.globals.tarball_location.version
  dsf_main_ip         = module.agentless_gw_main[count.index].private_ip
  dsf_main_private_ip = module.agentless_gw_main[count.index].private_ip
  dsf_dr_ip           = module.agentless_gw_dr[count.index].private_ip
  dsf_dr_private_ip   = module.agentless_gw_dr[count.index].private_ip
  ssh_key_path        = module.key_pair.private_key_file_path
  ssh_user            = module.agentless_gw_main[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  depends_on = [
    module.agentless_gw_main,
    module.agentless_gw_dr
  ]
}

locals {
  gws = merge(
    { for idx, val in module.agentless_gw_main : "agentless-gw-${idx}" => val },
    { for idx, val in module.agentless_gw_dr : "agentless-gw-dr-${idx}" => val },
  )
  gws_set = values(local.gws)
  hubs_set = concat(
    var.enable_sonar ? [module.hub_main[0]] : [],
    var.enable_sonar && var.hub_hadr ? [module.hub_dr[0]] : []
  )
  hubs_keys = compact([
    var.enable_sonar ? "hub-main" : null,
    var.enable_sonar && var.hub_hadr ? "hub-dr" : null,
  ])

  hub_gw_combinations_values = setproduct(local.hubs_set, local.gws_set)
  hub_gw_combinations_keys   = [for v in setproduct(local.hubs_keys, keys(local.gws)) : "${v[0]}-${v[1]}"]

  hub_gw_combinations = zipmap(local.hub_gw_combinations_keys, local.hub_gw_combinations_values)
}

module "federation" {
  source   = "imperva/dsf-federation/null"
  version  = "1.5.5" # latest release tag
  for_each = local.hub_gw_combinations

  hub_info = {
    hub_ip_address           = each.value[0].public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = each.value[0].ssh_user
  }
  gw_info = {
    gw_ip_address           = each.value[1].private_ip
    gw_private_ssh_key_path = module.key_pair.private_key_file_path
    gw_ssh_user             = each.value[1].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_hadr
  ]
}
