locals {
  tarball_location   = module.globals.tarball_location
  agentless_gw_count = var.enable_sonar ? var.agentless_gw_count : 0
}

module "hub" {
  source = "../../../modules/azurerm/hub"
  # version                             = "1.3.5" # latest release tag
  count = var.enable_sonar ? 1 : 0

  friendly_name               = join("-", [local.deployment_name_salted, "hub"])
  resource_group              = local.resource_group
  subnet_id                   = module.network[0].vnet_subnets[0]
  binaries_location           = local.tarball_location
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

module "hub_secondary" {
  source = "../../../modules/azurerm/hub"
  # version                             = "1.3.5" # latest release tag
  count = var.enable_sonar && var.hub_hadr ? 1 : 0

  friendly_name                   = join("-", [local.deployment_name_salted, "hub", "DR"])
  resource_group                  = local.resource_group
  subnet_id                       = module.network[0].vnet_subnets[1]
  binaries_location               = local.tarball_location
  password                        = local.password
  storage_details                 = var.hub_storage_details
  instance_type                   = var.hub_instance_type
  attach_persistent_public_ip     = true
  use_public_ip                   = true
  hadr_secondary_node             = true
  primary_node_sonarw_public_key  = module.hub[0].sonarw_public_key
  primary_node_sonarw_private_key = module.hub[0].sonarw_private_key
  generate_access_tokens          = true
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
  version = "1.5.1" # latest release tag
  count   = length(module.hub_secondary) > 0 ? 1 : 0

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.hub[0].public_ip
  dsf_primary_private_ip   = module.hub[0].private_ip
  dsf_secondary_ip         = module.hub_secondary[0].public_ip
  dsf_secondary_private_ip = module.hub_secondary[0].private_ip
  ssh_key_path             = local_sensitive_file.ssh_key.filename
  ssh_user                 = module.hub[0].ssh_user
  depends_on = [
    module.hub,
    module.hub_secondary
  ]
}

module "agentless_gw" {
  source = "../../../modules/azurerm/agentless-gw"
  # version                             = "1.3.5" # latest release tag
  count  = local.agentless_gw_count

  friendly_name         = join("-", [local.deployment_name_salted, "agentless", "gw", count.index])
  resource_group        = local.resource_group
  subnet_id             = module.network[0].vnet_subnets[0]
  storage_details       = var.agentless_gw_storage_details
  binaries_location     = local.tarball_location
  instance_type         = var.agentless_gw_instance_type
  password              = local.password
  hub_sonarw_public_key = module.hub[0].sonarw_public_key
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_agentless_gw_cidrs = module.network[0].vnet_address_space
  allowed_hub_cidrs = module.network[0].vnet_address_space
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.network
  ]
}

module "agentless_gw_secondary" {
  source = "../../../modules/azurerm/agentless-gw"
  # version                             = "1.3.5" # latest release tag
  count   = var.agentless_gw_hadr ? local.agentless_gw_count : 0

  friendly_name                   = join("-", [local.deployment_name_salted, "agentless", "gw", "DR", count.index])
  resource_group        = local.resource_group
  subnet_id             = module.network[0].vnet_subnets[1]
  storage_details       = var.agentless_gw_storage_details
  binaries_location     = local.tarball_location
  instance_type         = var.agentless_gw_instance_type
  password              = local.password
  hub_sonarw_public_key = module.hub[0].sonarw_public_key
  hadr_secondary_node             = true
  primary_node_sonarw_public_key  = module.agentless_gw[count.index].sonarw_public_key
  primary_node_sonarw_private_key = module.agentless_gw[count.index].sonarw_private_key
  ssh_key = {
    ssh_public_key            = tls_private_key.ssh_key.public_key_openssh
    ssh_private_key_file_path = local_sensitive_file.ssh_key.filename
  }
  allowed_agentless_gw_cidrs = module.network[0].vnet_address_space
  allowed_hub_cidrs = module.network[0].vnet_address_space
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.network
  ]
}

module "agentless_gw_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.5.1" # latest release tag
  count   = length(module.agentless_gw_secondary)

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.agentless_gw[count.index].private_ip
  dsf_primary_private_ip   = module.agentless_gw[count.index].private_ip
  dsf_secondary_ip         = module.agentless_gw_secondary[count.index].private_ip
  dsf_secondary_private_ip = module.agentless_gw_secondary[count.index].private_ip
  ssh_key_path             = local_sensitive_file.ssh_key.filename
  ssh_user                 = module.agentless_gw[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  depends_on = [
    module.agentless_gw,
    module.agentless_gw_secondary
  ]
}

locals {
  gws = merge(
    { for idx, val in module.agentless_gw : "agentless-gw-${idx}" => val },
    { for idx, val in module.agentless_gw_secondary : "agentless-gw-secondary-${idx}" => val },
  )
  gws_set = values(local.gws)
  hubs_set = concat(
    var.enable_sonar ? [module.hub[0]] : [],
    var.enable_sonar && var.hub_hadr ? [module.hub_secondary[0]] : []
  )
  hubs_keys = compact([
    var.enable_sonar ? "hub-primary" : null,
    var.enable_sonar && var.hub_hadr ? "hub-secondary" : null,
  ])

  hub_gw_combinations_values = setproduct(local.hubs_set, local.gws_set)
  hub_gw_combinations_keys   = [for v in setproduct(local.hubs_keys, keys(local.gws)) : "${v[0]}-${v[1]}"]

  hub_gw_combinations = zipmap(local.hub_gw_combinations_keys, local.hub_gw_combinations_values)
}

module "federation" {
  source   = "imperva/dsf-federation/null"
  version  = "1.5.1" # latest release tag
  for_each = local.hub_gw_combinations

  hub_info = {
    hub_ip_address           = each.value[0].public_ip
    hub_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    hub_ssh_user             = each.value[0].ssh_user
  }
  gw_info = {
    gw_ip_address           = each.value[1].private_ip
    gw_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    gw_ssh_user             = each.value[1].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = local_sensitive_file.ssh_key.filename
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_hadr
  ]
}
