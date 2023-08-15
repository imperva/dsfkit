# locals {
#   hub_subnet_id                    = var.subnet_ids != null ? var.subnet_ids.hub_subnet_id : module.vpc[0].public_subnets[0]
#   hub_secondary_subnet_id          = var.subnet_ids != null ? var.subnet_ids.hub_secondary_subnet_id : module.vpc[0].public_subnets[1]
#   agentless_gw_subnet_id           = var.subnet_ids != null ? var.subnet_ids.agentless_gw_subnet_id : module.vpc[0].private_subnets[0]
#   agentless_gw_secondary_subnet_id = var.subnet_ids != null ? var.subnet_ids.agentless_gw_secondary_subnet_id : module.vpc[0].private_subnets[1]
#   db_subnet_ids                    = var.subnet_ids != null ? var.subnet_ids.db_subnet_ids : module.vpc[0].public_subnets
#   mx_subnet_id                     = var.subnet_ids != null ? var.subnet_ids.mx_subnet_id : module.vpc[0].public_subnets[0]
#   dra_admin_subnet_id              = var.subnet_ids != null ? var.subnet_ids.admin_subnet_id : module.vpc[0].public_subnets[0]
#   dra_analytics_subnet_id          = var.subnet_ids != null ? var.subnet_ids.analytics_subnet_id : module.vpc[0].private_subnets[0]
#   agent_gw_subnet_id               = var.subnet_ids != null ? var.subnet_ids.agent_gw_subnet_id : module.vpc[0].private_subnets[0]
# }

# network
module "network" {
  count = 1
  source              = "Azure/network/azurerm"
  vnet_name           = "${local.deployment_name_salted}-${module.globals.current_user_name}"
  resource_group_name = azurerm_resource_group.rg.name
  address_spaces      = [var.vnet_ip_range]
  subnet_prefixes     = var.subnets_ip_range
  subnet_names        = formatlist("subnet-%d", range(length(var.subnets_ip_range)))

  use_for_each = true
  tags         = local.tags
  depends_on = [
    azurerm_resource_group.rg
  ]
}

# data "aws_subnet" "hub" {
#   id = local.hub_subnet_id
# }

# data "aws_subnet" "hub_secondary" {
#   id = local.hub_secondary_subnet_id
# }

# data "aws_subnet" "agentless_gw" {
#   id = local.agentless_gw_subnet_id
# }

# data "aws_subnet" "agentless_gw_secondary" {
#   id = local.agentless_gw_secondary_subnet_id
# }

# data "aws_subnet" "mx" {
#   id = local.mx_subnet_id
# }

# data "aws_subnet" "agent_gw" {
#   id = local.agent_gw_subnet_id
# }

# data "aws_subnet" "dra_admin" {
#   id = local.dra_admin_subnet_id
# }

# data "aws_subnet" "dra_analytics" {
#   id = local.dra_analytics_subnet_id
# }

# NAT

resource "azurerm_public_ip" "nat_gw_public_ip" {
  name                = join("-", [var.deployment_name, "nat", "public", "ip"])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                    = join("-", [var.deployment_name, "nat", "gw"])
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_subnet_nat_gateway_association" "nat_gw_vnet_association" {
  subnet_id      = module.network[0].vnet_subnets[0]
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gw_public_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_gw_public_ip.id
}
