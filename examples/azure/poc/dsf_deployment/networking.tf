locals {
  create_network = var.subnet_ids == null && var.subnet_id == null

  hub_subnet_id = coalesce(try(var.subnet_ids.hub_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[0], null))
  hub_dr_subnet_id = coalesce(try(var.subnet_ids.hub_dr_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[1], null))

  agentless_gw_subnet_id = coalesce(try(var.subnet_ids.agentless_gw_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[0], null))
  agentless_gw_dr_subnet_id = coalesce(try(var.subnet_ids.agentless_gw_dr_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[1], null))

  db_subnet_id = coalesce(try(var.subnet_ids.db_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[0], null))

  mx_subnet_id = coalesce(try(var.subnet_ids.mx_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[0], null))
  agent_gw_subnet_id = coalesce(try(var.subnet_ids.agent_gw_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[0], null))

  dra_admin_subnet_id = coalesce(try(var.subnet_ids.dra_admin_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[0], null))
  dra_analytics_subnet_id = coalesce(try(var.subnet_ids.dra_analytics_subnet_id, null), var.subnet_id, try(module.network[0].vnet_subnets[1], null))

  subnet_prefixes = cidrsubnets(var.vnet_ip_range, 8, 8)

  subnet_ids = [
    local.hub_subnet_id,
    local.hub_dr_subnet_id,
    local.agent_gw_subnet_id,
    local.agentless_gw_dr_subnet_id,
    local.db_subnet_id,
    local.mx_subnet_id,
    local.agent_gw_subnet_id,
    local.dra_admin_subnet_id,
    local.dra_analytics_subnet_id,
  ]

  ipv4_regex = "([0-9]{1,3}\\.){3}[0-9]{1,3}(/([0-9]|[1-2][0-9]|3[0-2]))?"

  _all_subnet_address_spaces = distinct(sort(
    concat([
      for subnet in data.azurerm_subnet.all_subnets :
      subnet.address_prefixes
    ]...)
  ))

  # we can't currently use ipv6 IPs
  all_subnet_address_spaces = [
    for cidr in local._all_subnet_address_spaces: cidr
    if can(regex(local.ipv4_regex, cidr))
  ]
}

data "azurerm_subnet" "all_subnets" {
  for_each = {
    for index, id in local.subnet_ids : index => id
  }

  resource_group_name  = split("/", each.value)[4]
  virtual_network_name = split("/", each.value)[8]
  name                 = split("/", each.value)[10]
}

# network
module "network" {
  count               = local.create_network ? 1 : 0
  source              = "Azure/network/azurerm"
  version             = "5.3.0"
  vnet_name           = "${local.deployment_name_salted}-${module.globals.current_user_name}"
  resource_group_name = local.resource_group.name
  address_spaces      = [var.vnet_ip_range]
  subnet_prefixes     = local.subnet_prefixes
  subnet_names        = formatlist("subnet-%d", range(length(local.subnet_prefixes)))

  use_for_each = true
  tags         = local.tags
  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_public_ip" "nat_gw_public_ip" {
  count               = local.create_network ? 1 : 0
  name                = join("-", [var.deployment_name, "nat", "public", "ip"])
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  count                   = local.create_network ? 1 : 0
  name                    = join("-", [var.deployment_name, "nat", "gw"])
  location                = local.resource_group.location
  resource_group_name     = local.resource_group.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gw_public_ip_association" {
  count                = local.create_network ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.nat_gw[0].id
  public_ip_address_id = azurerm_public_ip.nat_gw_public_ip[0].id
}

# subnet 1 is the private subnet
resource "azurerm_subnet_nat_gateway_association" "nat_gw_vnet_association" {
  count          = local.create_network ? 1 : 0
  subnet_id      = module.network[0].vnet_subnets[1]
  nat_gateway_id = azurerm_nat_gateway.nat_gw[0].id
}