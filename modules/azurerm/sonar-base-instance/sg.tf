locals {
  create_security_group_count = var.security_group_id == null ? 1 : 0
  cidr_blocks                 = var.sg_ingress_cidr
  ingress_ports               = [22, 8080, 8443, 3030, 27117]
  ingress_ports_map           = { for port in local.ingress_ports : port => port }
  local_port_start            = 10800
  local_port_end              = 10899
}

resource "azurerm_network_security_group" "dsf_base_sg" {
  count               = local.create_security_group_count
  name                = join("-", [var.name, "sg"])
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_network_security_rule" "sg_rule_all_out" {
  count                       = local.create_security_group_count
  name                        = join("-", [var.name, "sg", "all", "out"])
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.dsf_base_sg[0].name
}

resource "azurerm_network_security_rule" "sg_cidr_ingress" {
  count                       = local.create_security_group_count
  name                        = join("-", [var.name, "sg", "all", "in"])
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = local.ingress_ports
  source_address_prefixes     = local.cidr_blocks
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.dsf_base_sg[0].name
}

resource "azurerm_network_security_rule" "sg_webconsole_ingress" {
  count                       = (length(var.web_console_cidr) != 0) && (local.create_security_group_count > 0) ? 1 : 0
  name                        = join("-", [var.name, "sg", "webconsole", "in"])
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 8443
  source_address_prefixes     = var.web_console_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.dsf_base_sg[0].name
}
