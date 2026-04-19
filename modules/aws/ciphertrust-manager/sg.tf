locals {
  # Skip sg creation if external sg list is given
  _security_groups_config = length(var.security_group_ids) == 0 ? local.security_groups_config : []

  security_groups_config = [ // https://docs-cybersec.thalesgroup.com/bundle/latest-cdsp-cm/page/get_started/deployment/hardening-guidelines/index.html
    {
      name            = ["web", "console", "and", "api"]
      internet_access = false
      udp             = []
      tcp             = [443, 80]
      cidrs           = concat(var.allowed_web_console_and_api_cidrs, var.allowed_cte_agents_cidrs, var.allowed_hub_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["ssh"]
      internet_access = true
      udp             = []
      tcp             = [22]
      cidrs           = concat(var.allowed_ssh_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["cluster", "nodes"]
      internet_access = false
      udp             = []
      tcp             = [5432, 2380]
      cidrs           = concat(var.allowed_cluster_nodes_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["ddc", "agents"]
      internet_access = false
      udp             = []
      tcp             = [11117]
      cidrs           = concat(var.allowed_ddc_agents_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["other"]
      internet_access = false
      udp             = []
      tcp             = [5696, 9000]
      cidrs           = concat(var.allowed_all_cidrs)
    }
  ]
}

data "aws_subnet" "subnet" {
  id = var.subnet_id
}

##############################################################################
### Ingress security group
##############################################################################

resource "aws_security_group" "sg" {
  for_each    = { for idx, config in local._security_groups_config : idx => config }
  name        = join("-", [var.friendly_name, join("-", each.value.name)])
  vpc_id      = data.aws_subnet.subnet.vpc_id
  description = format("%s - %s ingress access", var.friendly_name, join(" ", each.value.name))

  dynamic "ingress" {
    for_each = { for idx, port in each.value.tcp : idx => port }
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = each.value.cidrs
    }
  }

  dynamic "ingress" {
    for_each = { for idx, port in each.value.udp : idx => port }
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "udp"
      cidr_blocks = each.value.cidrs
    }
  }

  # Conditionally assign egress rules based on a "internet_access" memeber
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = each.value.internet_access ? ["0.0.0.0/0"] : []
    ipv6_cidr_blocks = each.value.internet_access ? ["::/0"] : []
  }

  tags = merge(var.tags, { Name = join("-", [var.friendly_name, join("-", each.value.name)]) })
}