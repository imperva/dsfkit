resource "azurerm_public_ip" "example" {
  name                = join("-", [local.deployment_name_salted, "nat", "public", "ip"])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  # zones               = ["1"]
}

resource "azurerm_nat_gateway" "example" {
  name                    = join("-", [local.deployment_name_salted, "nat", "gw"])
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  # zones                   = ["1"]
}

resource "azurerm_subnet_nat_gateway_association" "example" {
  subnet_id      = module.network.vnet_subnets[0]
  nat_gateway_id = azurerm_nat_gateway.example.id
}

resource "azurerm_nat_gateway_public_ip_association" "example" {
  nat_gateway_id       = azurerm_nat_gateway.example.id
  public_ip_address_id = azurerm_public_ip.example.id
}
