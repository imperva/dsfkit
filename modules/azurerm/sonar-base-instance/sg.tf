locals {
  # Skip sg creation if external sg list is given
  _security_groups_config = length(var.security_group_ids) == 0 ? var.security_groups_config : []
}

##############################################################################
### Ingress security group 
##############################################################################

resource "azurerm_network_security_group" "dsf_base_sg" {
  name                = var.name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name

  dynamic "security_rule" {
    for_each = { for idx, config in local._security_groups_config : idx => config if length(config.cidrs) > 0 }
    content {
      name                       = join("-", [var.name, "tcp", join("-", security_rule.value.name)])
      priority                   = 100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = security_rule.value.tcp
      source_address_prefixes    = security_rule.value.cidrs
      destination_address_prefix = "*"
    }
  }
  tags = var.tags
}