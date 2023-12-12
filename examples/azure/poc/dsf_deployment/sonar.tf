locals {
  agentless_gw_count = var.enable_sonar ? var.agentless_gw_count : 0
}

module "hub_main" {
  source  = "imperva/dsf-hub/azurerm"
  version = "1.7.2" # latest release tag
  count   = var.enable_sonar ? 1 : 0

  friendly_name               = join("-", [local.deployment_name_salted, "hub"])
  resource_group              = local.resource_group
  subnet_id                   = module.network[0].vnet_subnets[0]
  binaries_location           = var.tarball_location
  password                    = local.password
  storage_details             = var.hub_storage_details
  instance_type               = var.hub_instance_type
  attach_persistent_public_ip = true
  use_public_ip               = true
  generate_access_tokens      = true
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = module.network[0].vnet_address_space
  allowed_agentless_gw_cidrs        = module.network[0].vnet_address_space
  allowed_all_cidrs                 = local.workstation_cidr
  tags                              = local.tags

  depends_on = [
    module.network
  ]
}

module "hub_dr" {
  source  = "imperva/dsf-hub/azurerm"
  version = "1.7.2" # latest release tag
  count   = var.enable_sonar && var.hub_hadr ? 1 : 0

  friendly_name                = join("-", [local.deployment_name_salted, "hub", "DR"])
  resource_group               = local.resource_group
  subnet_id                    = module.network[0].vnet_subnets[1]
  binaries_location            = var.tarball_location
  password                     = local.password
  storage_details              = var.hub_storage_details
  instance_type                = var.hub_instance_type
  attach_persistent_public_ip  = true
  use_public_ip                = true
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.hub_main[0].sonarw_public_key
  main_node_sonarw_private_key = module.hub_main[0].sonarw_private_key
  generate_access_tokens       = true
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = module.network[0].vnet_address_space
  allowed_agentless_gw_cidrs        = module.network[0].vnet_address_space
  allowed_all_cidrs                 = local.workstation_cidr
  tags                              = local.tags
  depends_on = [
    module.network
  ]
}

module "hub_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.7.2" # latest release tag
  count   = length(module.hub_dr) > 0 ? 1 : 0

  sonar_version       = var.sonar_version
  dsf_main_ip         = module.hub_main[0].public_ip
  dsf_main_private_ip = module.hub_main[0].private_ip
  dsf_dr_ip           = module.hub_dr[0].public_ip
  dsf_dr_private_ip   = module.hub_dr[0].private_ip
  ssh_key_path        = local_sensitive_file.ssh_key.filename
  ssh_user            = module.hub_main[0].ssh_user
  depends_on = [
    module.hub_main,
    module.hub_dr
  ]
}

module "agentless_gw_main" {
  source  = "imperva/dsf-agentless-gw/azurerm"
  version = "1.7.2" # latest release tag
  count   = local.agentless_gw_count

  friendly_name         = join("-", [local.deployment_name_salted, "agentless", "gw", count.index])
  resource_group        = local.resource_group
  subnet_id             = module.network[0].vnet_subnets[0]
  storage_details       = var.agentless_gw_storage_details
  binaries_location     = var.tarball_location
  instance_type         = var.agentless_gw_instance_type
  password              = local.password
  hub_sonarw_public_key = module.hub_main[0].sonarw_public_key
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_agentless_gw_cidrs = module.network[0].vnet_address_space
  allowed_hub_cidrs          = module.network[0].vnet_address_space
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.network
  ]
}

module "agentless_gw_dr" {
  source  = "imperva/dsf-agentless-gw/azurerm"
  version = "1.7.2" # latest release tag
  count   = var.agentless_gw_hadr ? local.agentless_gw_count : 0

  friendly_name                = join("-", [local.deployment_name_salted, "agentless", "gw", count.index, "DR"])
  resource_group               = local.resource_group
  subnet_id                    = module.network[0].vnet_subnets[1]
  storage_details              = var.agentless_gw_storage_details
  binaries_location            = var.tarball_location
  instance_type                = var.agentless_gw_instance_type
  password                     = local.password
  hub_sonarw_public_key        = module.hub_main[0].sonarw_public_key
  hadr_dr_node                 = true
  main_node_sonarw_public_key  = module.agentless_gw_main[count.index].sonarw_public_key
  main_node_sonarw_private_key = module.agentless_gw_main[count.index].sonarw_private_key
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_agentless_gw_cidrs = module.network[0].vnet_address_space
  allowed_hub_cidrs          = module.network[0].vnet_address_space
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.network
  ]
}

module "agentless_gw_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.7.2" # latest release tag
  count   = length(module.agentless_gw_dr)

  sonar_version       = var.sonar_version
  dsf_main_ip         = module.agentless_gw_main[count.index].private_ip
  dsf_main_private_ip = module.agentless_gw_main[count.index].private_ip
  dsf_dr_ip           = module.agentless_gw_dr[count.index].private_ip
  dsf_dr_private_ip   = module.agentless_gw_dr[count.index].private_ip
  ssh_key_path        = local_sensitive_file.ssh_key.filename
  ssh_user            = module.agentless_gw_main[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
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
  version  = "1.7.2" # latest release tag
  for_each = local.hub_gw_combinations

  hub_info = {
    hub_ip_address            = each.value[0].public_ip
    hub_federation_ip_address = each.value[0].public_ip
    hub_private_ssh_key_path  = local_sensitive_file.ssh_key.filename
    hub_ssh_user              = each.value[0].ssh_user
  }
  gw_info = {
    gw_ip_address            = each.value[1].private_ip
    gw_federation_ip_address = each.value[1].private_ip
    gw_private_ssh_key_path  = local_sensitive_file.ssh_key.filename
    gw_ssh_user              = each.value[1].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub_main[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub_main[0].ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_hadr
  ]
}
