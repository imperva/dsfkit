locals {
  create_network = var.subnet_ids == null && var.subnet_id == null

  hub_subnet_id = coalesce(try(var.subnet_ids.hub_subnet_id, null), var.subnet_id, module.network[0].vnet_subnets[0])
  hub_dr_subnet_id = coalesce(try(var.subnet_ids.hub_dr_subnet_id, null), var.subnet_id, module.network[0].vnet_subnets[1])

  agentless_gw_subnet_id = coalesce(try(var.subnet_ids.agentless_gw_subnet_id, null), var.subnet_id, module.network[0].vnet_subnets[0])
  agentless_gw_dr_subnet_id = coalesce(try(var.subnet_ids.agentless_gw_dr_subnet_id, null), var.subnet_id, module.network[0].vnet_subnets[1])

  db_subnet_ids = coalescelist(try(var.subnet_ids.db_subnet_ids, []), compact([var.subnet_id]), module.network[0].vnet_subnets)

  mx_subnet_id = coalesce(try(var.subnet_ids.mx_subnet_id, null), var.subnet_id, module.network[0].vnet_subnets[0])
  agent_gw_subnet_id = coalesce(try(var.subnet_ids.agent_gw_subnet_id, null), var.subnet_id, module.network[0].vnet_subnets[0])

  dra_admin_subnet_id = coalesce(try(var.subnet_ids.dra_admin_subnet_id, null), var.subnet_id, module.network[0].vnet_subnets[0])
  dra_analytics_subnet_id = coalesce(try(var.subnet_ids.dra_analytics_subnet_id, null), var.subnet_id, module.network[0].vnet_subnets[1])

  subnet_prefixes = cidrsubnets(var.vnet_ip_range, 8, 8)
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