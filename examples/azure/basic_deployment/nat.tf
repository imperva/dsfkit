resource "azurerm_public_ip" "nat_gw_public_ip" {
  name                = join("-", [local.deployment_name_salted, "nat", "public", "ip"])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                    = join("-", [local.deployment_name_salted, "nat", "gw"])
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_subnet_nat_gateway_association" "nat_gw_vnet_association" {
  subnet_id      = module.network.vnet_subnets[0]
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gw_public_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_gw_public_ip.id
}
