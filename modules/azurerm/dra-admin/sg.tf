locals {
  security_groups_config = [ # https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/63052.htm
    {
      name            = ["web", "console"]
      internet_access = false
      udp             = []
      tcp             = [8443]
      cidrs           = concat(var.allowed_web_console_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["other"]
      internet_access = true
      udp             = []
      tcp             = [22]
      cidrs           = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["dra", "analytics"]
      internet_access = false
      udp             = []
      tcp             = [61617, 8443, 8501]
      cidrs           = concat(var.allowed_analytics_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["hub"]
      internet_access = false
      udp             = []
      tcp             = [8443, 61617, 8501]
      cidrs           = concat(var.allowed_hub_cidrs, var.allowed_all_cidrs)
    }
  ]

  # Skip sg creation if external sg list is given
  _security_groups_config = length(var.security_group_ids) == 0 ? local.security_groups_config : []
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
      name                    = join("-", [var.name, "tcp", join("-", security_rule.value.name)])
      priority                = 100 + security_rule.key
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = security_rule.value.tcp
      # Azure doesn't allow overlapping cidr blocks in a single rule. that's what the code below fixes
      source_address_prefixes = [for k, v in { for v in security_rule.value.cidrs : v => {
        cidr       = v,
        min_ip_int = (tonumber(split(".", cidrhost(v, 0))[0]) * pow(256, 3)) + (tonumber(split(".", cidrhost(v, 0))[1]) * pow(256, 2)) + (tonumber(split(".", cidrhost(v, 0))[2]) * pow(256, 1)) + tonumber(split(".", cidrhost(v, 0))[3])
        max_ip_int = (tonumber(split(".", cidrhost(v, -1))[0]) * pow(256, 3)) + (tonumber(split(".", cidrhost(v, -1))[1]) * pow(256, 2)) + (tonumber(split(".", cidrhost(v, -1))[2]) * pow(256, 1)) + tonumber(split(".", cidrhost(v, -1))[3])
      } } : v.cidr if !anytrue([for i in { for v in security_rule.value.cidrs : v => {
        cidr       = v,
        min_ip_int = (tonumber(split(".", cidrhost(v, 0))[0]) * pow(256, 3)) + (tonumber(split(".", cidrhost(v, 0))[1]) * pow(256, 2)) + (tonumber(split(".", cidrhost(v, 0))[2]) * pow(256, 1)) + tonumber(split(".", cidrhost(v, 0))[3])
        max_ip_int = (tonumber(split(".", cidrhost(v, -1))[0]) * pow(256, 3)) + (tonumber(split(".", cidrhost(v, -1))[1]) * pow(256, 2)) + (tonumber(split(".", cidrhost(v, -1))[2]) * pow(256, 1)) + tonumber(split(".", cidrhost(v, -1))[3])
      } } : v.max_ip_int <= i.max_ip_int && v.min_ip_int >= i.min_ip_int if v.cidr != i.cidr])]
      destination_address_prefix = "*"
      # The below setup is a workaround for "Provider produced inconsistent final plan" error
      description = ""
      destination_port_range = ""
      source_address_prefix = ""
    }
  }
  tags = var.tags
}