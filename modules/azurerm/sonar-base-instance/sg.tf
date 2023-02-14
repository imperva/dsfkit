locals {
  cidr_blocks   = concat(var.sg_ingress_cidr, var.create_and_attach_public_elastic_ip ? try(["${data.azurerm_public_ip.vm_public_ip[0].ip_address}/32"], []) : [])
  ingress_ports = [22, 8080, 8443, 3030, 27117]

  ingress_cidrs_map = { for cidr in local.cidr_blocks : cidr => cidr }
  ingress_ports_map = { for port in local.ingress_ports : port => port }
}

resource "azurerm_network_security_group" "dsf_base_sg" {
  name                = join("-", [var.name, "sg"])
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

# tbd: https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview#security-rules

# # resource "aws_security_group_rule" "all_in" {
# #   type        = "ingress"
# #   from_port   = 0
# #   to_port     = 0
# #   protocol    = "-1"
# #   cidr_blocks = ["0.0.0.0/0"]
# #   security_group_id = aws_security_group.dsf_base_sg.id
# # }

resource "azurerm_network_security_rule" "sg_rule_all_out" {
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
  network_security_group_name = azurerm_network_security_group.dsf_base_sg.name
}

# tbd: remove
resource "azurerm_network_security_rule" "sg_rule_all_in" {
  name                        = join("-", [var.name, "sg", "all", "in"])
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group.name
  network_security_group_name = azurerm_network_security_group.dsf_base_sg.name
}

# resource "azurerm_network_security_rule" "sg_rule_cidr_in" {
#   for_each                    = local.ingress_cidrs_map
#   name                        = join("-", [var.name, "sg", "in", each.key])
#   priority                    = 100 + each.key
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = local.ingress_ports
#   source_address_prefix       = "*"
#   destination_address_prefix  = each.value
#   resource_group_name         = var.resource_group.name
#   network_security_group_name = azurerm_network_security_group.dsf_base_sg.name
# }

# resource "aws_security_group_rule" "sg_self" {
#   for_each          = local.ingress_ports_map
#   type              = "ingress"
#   from_port         = each.value
#   to_port           = each.value
#   protocol          = "tcp"
#   self              = true
#   security_group_id = aws_security_group.dsf_base_sg.id
# }

# resource "aws_security_group_rule" "sonarrsyslog_self" {
#   type              = "ingress"
#   from_port         = 10800
#   to_port           = 10899
#   protocol          = "tcp"
#   self              = true
#   security_group_id = aws_security_group.dsf_base_sg.id
# }

# resource "aws_security_group_rule" "sg_ingress_self" {
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 65535
#   protocol          = "tcp"
#   self              = true
#   security_group_id = aws_security_group.dsf_base_sg.id
# }

# resource "aws_security_group_rule" "sg_web_console_access" {
#   count             = length(var.web_console_cidr) == 0 ? 0 : 1
#   type              = "ingress"
#   from_port         = 8443
#   to_port           = 8443
#   protocol          = "tcp"
#   cidr_blocks       = var.web_console_cidr
#   security_group_id = aws_security_group.dsf_base_sg.id
# }

# resource "aws_security_group_rule" "sg_allow_ssh_in_vpc" {
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = [data.aws_vpc.selected.cidr_block]
#   security_group_id = aws_security_group.dsf_base_sg.id
# }
