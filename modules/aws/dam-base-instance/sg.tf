data "aws_subnet" "subnet" {
  id = var.subnet_id
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.selected_subnet.vpc_id
}

locals {
  cidr_blocks       = var.sg_ingress_cidr
  ingress_ports     = var.ports.tcp
  udp_ingress_ports     = var.ports.udp
  ingress_ports_map = length(local.cidr_blocks) > 0 ? { for port in local.ingress_ports : port => port } : {}
  vpc_udp_ingress_ports_map = length(local.cidr_blocks) > 0 ? { for port in local.udp_ingress_ports : port => port } : {}
  vpc_ingress_ports_map = { for port in local.ingress_ports : port => port }
}

resource "aws_security_group" "dsf_base_sg" {
  description = "Public internet access"
  vpc_id      = data.aws_subnet.subnet.vpc_id

  tags = {
    Name = join("-", [var.name, "sg"])
  }
}

resource "aws_security_group_rule" "all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_cidr_ingress" {
  for_each          = local.ingress_ports_map
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = local.cidr_blocks
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_cidr_ingress_udp" {
  for_each          = local.vpc_udp_ingress_ports_map
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "udp"
  cidr_blocks       = local.cidr_blocks
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_web_console_access" {
  count = length(var.web_console_cidr) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 8083
  to_port           = 8083
  protocol          = "tcp"
  cidr_blocks       = var.web_console_cidr
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_allow_ssh_in_vpc" {
  for_each          = local.vpc_ingress_ports_map
  description       = "vpc "
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_allow_all_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dsf_base_sg.id
}
