locals {
  # Skip sg creation if external sg list is given
  _security_groups_config = length(var.security_group_ids) == 0 ? var.security_groups_config : []
}

##############################################################################
### Ingress security group 
##############################################################################

resource "azurerm_network_security_group" "dsf_base_sg" {
  # for_each    = { for idx, config in local._security_groups_config : idx => config }
  # name        = join("-", [var.name, join("-", each.value.name)])
  name        = var.name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  dynamic "security_rule" {
    for_each = { for idx, config in local._security_groups_config : idx => config }
    # for_each = { for idx, port in each.value.tcp : idx => port }
    content {
      name = join("-", [var.name, "tcp", join("-", security_rule.value.name)])
      # description = format("%s - %s ingress access", var.name, join(" ", each.value.name))
      priority                    = 100 + security_rule.key
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Tcp"
      source_port_range           = "*"
      # destination_port_ranges     = ["${security_rule.value}"]
      destination_port_ranges     = security_rule.value.tcp
      source_address_prefixes     = security_rule.value.cidrs
      destination_address_prefix  = "*"
    }
  }

  # dynamic "security_rule" {
  #   for_each = { for idx, port in each.value.udp : idx => port }
  #   content {
  #     name = join("-", [var.name, "udp", security_rule.value])
  #     # description = format("%s - %s ingress access", var.name, join(" ", each.value.name))
  #     priority                    = 150 + 100 * each.key + security_rule.key
  #     direction                   = "Inbound"
  #     access                      = "Allow"
  #     protocol                    = "Udp"
  #     source_port_range           = "*"
  #     destination_port_ranges     = ["${security_rule.value}"]
  #     source_address_prefixes     = each.value.cidrs
  #     destination_address_prefix  = "*"
  #   }
  # }

  # # Conditionally assign egress rules based on a "internet_access" memeber
  # egress {
  #   from_port        = 0
  #   to_port          = 0
  #   protocol         = "-1"
  #   cidr_blocks      = each.value.internet_access ? ["0.0.0.0/0"] : []
  #   ipv6_cidr_blocks = each.value.internet_access ? ["::/0"] : []
  # }

  # tags = merge(var.tags, { Name = join("-", [var.name, join("-", each.value.name)]) })
}

# locals {
#   create_security_group_count = length(var.security_group_ids) > 0 ? 1 : 0
#   # cidr_blocks                 = var.sg_ingress_cidr
#   ingress_ports               = [22, 8080, 8443, 3030, 27117]
#   ingress_ports_map           = { for port in local.ingress_ports : port => port }
#   local_port_start            = 10800
#   local_port_end              = 10899
# }

# resource "azurerm_network_security_group" "dsf_base_sg" {
#   count               = local.create_security_group_count
#   name                = join("-", [var.name, "sg"])
#   location            = var.resource_group.location
#   resource_group_name = var.resource_group.name
# }

# resource "azurerm_network_security_rule" "sg_rule_all_out" {
#   count                       = local.create_security_group_count
#   name                        = join("-", [var.name, "sg", "all", "out"])
#   priority                    = 100
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = var.resource_group.name
#   network_security_group_name = azurerm_network_security_group.dsf_base_sg[0].name
# }

# resource "azurerm_network_security_rule" "sg_cidr_ingress" {
#   count                       = local.create_security_group_count
#   name                        = join("-", [var.name, "sg", "all", "in"])
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_ranges     = local.ingress_ports
#   source_address_prefixes     = local.cidr_blocks
#   destination_address_prefix  = "*"
#   resource_group_name         = var.resource_group.name
#   network_security_group_name = azurerm_network_security_group.dsf_base_sg[0].name
# }

# resource "azurerm_network_security_rule" "sg_webconsole_ingress" {
#   count                       = (length(var.web_console_cidr) != 0) && (local.create_security_group_count > 0) ? 1 : 0
#   name                        = join("-", [var.name, "sg", "webconsole", "in"])
#   priority                    = 101
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = 8443
#   source_address_prefixes     = var.web_console_cidr
#   destination_address_prefix  = "*"
#   resource_group_name         = var.resource_group.name
#   network_security_group_name = azurerm_network_security_group.dsf_base_sg[0].name
# }
