resource "azurerm_network_security_group" "dsf_agent_sg" {
  name                = var.friendly_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_network_security_rule" "all_out" {
  name                        = "AllowAllOut"
  description                 = "${var.friendly_name} - Allow all out"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.dsf_agent_sg.name
}

resource "azurerm_network_security_rule" "sg_cidr_ingress" {
  name                   = "AllowSshLocal"
  description            = "${var.friendly_name} - Allow ssh local"
  priority               = 100
  direction              = "Inbound"
  access                 = "Allow"
  protocol               = "Tcp"
  source_port_range      = "*"
  destination_port_range = "22"
  # Azure doesn't allow overlapping cidr blocks in a single rule. that's what the code below fixes
  source_address_prefixes = [for k, v in { for v in var.allowed_ssh_cidrs : v => {
    cidr       = v,
    min_ip_int = (tonumber(split(".", cidrhost(v, 0))[0]) * pow(256, 3)) + (tonumber(split(".", cidrhost(v, 0))[1]) * pow(256, 2)) + (tonumber(split(".", cidrhost(v, 0))[2]) * pow(256, 1)) + tonumber(split(".", cidrhost(v, 0))[3])
    max_ip_int = (tonumber(split(".", cidrhost(v, -1))[0]) * pow(256, 3)) + (tonumber(split(".", cidrhost(v, -1))[1]) * pow(256, 2)) + (tonumber(split(".", cidrhost(v, -1))[2]) * pow(256, 1)) + tonumber(split(".", cidrhost(v, -1))[3])
    } } : v.cidr if !anytrue([for i in { for v in var.allowed_ssh_cidrs : v => {
      cidr       = v,
      min_ip_int = (tonumber(split(".", cidrhost(v, 0))[0]) * pow(256, 3)) + (tonumber(split(".", cidrhost(v, 0))[1]) * pow(256, 2)) + (tonumber(split(".", cidrhost(v, 0))[2]) * pow(256, 1)) + tonumber(split(".", cidrhost(v, 0))[3])
      max_ip_int = (tonumber(split(".", cidrhost(v, -1))[0]) * pow(256, 3)) + (tonumber(split(".", cidrhost(v, -1))[1]) * pow(256, 2)) + (tonumber(split(".", cidrhost(v, -1))[2]) * pow(256, 1)) + tonumber(split(".", cidrhost(v, -1))[3])
  } } : v.max_ip_int <= i.max_ip_int && v.min_ip_int >= i.min_ip_int if v.cidr != i.cidr])]
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.dsf_agent_sg.name
}