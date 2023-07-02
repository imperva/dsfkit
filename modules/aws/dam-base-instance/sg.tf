data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

locals {
  # Skip sg creation if external sg list is given
  _security_groups_config = length(var.security_group_ids) == 0 ? var.security_groups_config : []
}

##############################################################################
### Ingress security group 
##############################################################################

resource "aws_security_group" "dsf_base_sg_in" {
  for_each    = { for idx, config in local._security_groups_config : idx => config }
  name        = join("-", [var.name, join(" ", each.value.name)])
  vpc_id      = data.aws_subnet.selected_subnet.vpc_id
  description = format("%s - %s ingress access", var.name, join(" ", each.value.name))

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

  tags = merge(var.tags, { Name = join("-", [var.name, join(" ", each.value.name)]) })
}
