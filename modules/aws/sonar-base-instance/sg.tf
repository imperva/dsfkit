data "aws_subnet" "subnet" {
  id = var.subnet_id
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.selected_subnet.vpc_id
}

locals {
  should_create_security_group = var.security_group_id == "" ? true : false
  cidr_blocks                  = var.sg_ingress_cidr
  ingress_ports                = [22, 8080, 8443, 3030, 27117]
  ingress_ports_map            = { for port in local.ingress_ports : port => port }
}

resource "aws_security_group" "dsf_base_sg" {
  count       = local.should_create_security_group == true ? 1 : 0
  description = "Public internet access"
  vpc_id      = data.aws_subnet.subnet.vpc_id

  tags = {
    Name = join("-", [var.name, "sg"])
  }
}

resource "aws_security_group_rule" "all_out" {
  count             = local.should_create_security_group == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dsf_base_sg[0].id
}

resource "aws_security_group_rule" "sg_cidr_ingress" {
  for_each          = local.should_create_security_group == true ? local.ingress_ports_map : {}
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = local.cidr_blocks
  security_group_id = aws_security_group.dsf_base_sg[0].id
}

resource "aws_security_group_rule" "sg_self" {
  for_each          = local.should_create_security_group == true ? local.ingress_ports_map : {}
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.dsf_base_sg[0].id
}

resource "aws_security_group_rule" "sonarrsyslog_self" {
  count             = local.should_create_security_group == true ? 1 : 0
  type              = "ingress"
  from_port         = 10800
  to_port           = 10899
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.dsf_base_sg[0].id
}

resource "aws_security_group_rule" "sg_ingress_self" {
  count             = local.should_create_security_group == true ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.dsf_base_sg[0].id
}

resource "aws_security_group_rule" "sg_web_console_access" {
  count             = (length(var.web_console_cidr) != 0) && (local.should_create_security_group == true) ? 1 : 0
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = var.web_console_cidr
  security_group_id = aws_security_group.dsf_base_sg[0].id
}

resource "aws_security_group_rule" "sg_allow_ssh_in_vpc" {
  count             = local.should_create_security_group == true ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.dsf_base_sg[0].id
}
