data "aws_vpc" "selected" {
  id = data.aws_subnet.selected_subnet.vpc_id
}

locals {
  cidr_blocks           = var.sg_ingress_cidr
  ingress_ports         = var.ports.tcp
  udp_ingress_ports     = var.ports.udp
  ingress_ports_map     = { for port in local.ingress_ports : port => port }
  udp_ingress_ports_map = { for port in local.udp_ingress_ports : port => port }
}

##############################################################################
### Basic security group (vpc, and additional requires cidr blocks)
##############################################################################

resource "aws_security_group" "dsf_base_sg" {
  description = "${var.name} - Basic security group"
  vpc_id      = data.aws_subnet.selected_subnet.vpc_id

  tags = {
    Name = join("-", [var.name, "sg"])
  }
}

resource "aws_security_group_rule" "all_out" {
  description       = "${var.name} - Allow all out"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_cidr_ingress" {
  for_each          = local.ingress_ports_map
  description       = "${var.name} - Allow ${each.value}"
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = concat(local.cidr_blocks, [data.aws_vpc.selected.cidr_block])
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_cidr_ingress_udp" {
  for_each          = local.udp_ingress_ports_map
  description       = "${var.name} - Allow udp ${each.value}"
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "udp"
  cidr_blocks       = concat(local.cidr_blocks, [data.aws_vpc.selected.cidr_block])
  security_group_id = aws_security_group.dsf_base_sg.id
}

##############################################################################
### Web console security group
##############################################################################
resource "aws_security_group" "dsf_web_console_sg" {
  description = "${var.name} - web console access"
  vpc_id      = data.aws_subnet.selected_subnet.vpc_id

  tags = {
    Name = join("-", [var.name, "web", "console", "sg"])
  }
}

resource "aws_security_group_rule" "dsf_ssh_web_console_rule" {
  count             = length(var.web_console_cidr) > 0 ? 1 : 0
  description       = "${var.name} - Allow 8083 for web console access"
  type              = "ingress"
  from_port         = 8083
  to_port           = 8083
  protocol          = "tcp"
  cidr_blocks       = var.web_console_cidr
  security_group_id = aws_security_group.dsf_web_console_sg.id
}

##############################################################################
### SSH security group
##############################################################################
resource "aws_security_group" "dsf_ssh_sg" {
  description = "${var.name} - ssh access"
  vpc_id      = data.aws_subnet.selected_subnet.vpc_id

  tags = {
    Name = join("-", [var.name, "ssh", "sg"])
  }
}

resource "aws_security_group_rule" "dsf_ssh_sg_rule" {
  count             = length(var.sg_ssh_cidr) > 0 ? 1 : 0
  description       = "${var.name} - Allow ssh"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.sg_ssh_cidr
  security_group_id = aws_security_group.dsf_ssh_sg.id
}
