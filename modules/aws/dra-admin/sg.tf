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
      name            = ["analytics", "server"]
      internet_access = false
      udp             = []
      tcp             = [61617, 8443, 8501]
      cidrs           = concat(var.allowed_analytics_server_cidrs, var.allowed_all_cidrs)
    },
    {
      name            = ["hub"]
      internet_access = false
      udp             = []
      tcp             = [8443, 61617, 8501]
      cidrs           = concat(var.allowed_hub_cidrs, var.allowed_all_cidrs)
    }
  ]
}

data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

##############################################################################
### Ingress security group
##############################################################################

resource "aws_security_group" "dsf_base_sg_in" {
  for_each    = { for idx, config in local.security_groups_config : idx => config }
  name        = join("-", [var.friendly_name, join(" ", each.value.name)])
  vpc_id      = data.aws_subnet.selected_subnet.vpc_id
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

  tags = merge(var.tags, { Name = join("-", [var.friendly_name, join(" ", each.value.name)]) })
}
