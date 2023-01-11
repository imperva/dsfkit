data "aws_subnet" "subnet" {
  id = var.subnet_id
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.selected_subnet.vpc_id
}

locals {
  cidr_blocks       = concat(var.sg_ingress_cidr, var.create_and_attach_public_elastic_ip ? try(["${aws_eip.dsf_instance_eip[0].public_ip}/32"], []) : [])
  ingress_ports     = [22, 8080, 8443, 3030, 27117]
  ingress_ports_map = { for port in local.ingress_ports : port => port }
}

resource "aws_security_group" "dsf_base_sg" {
  description = "Public internet access"
  vpc_id      = data.aws_subnet.subnet.vpc_id

  tags = {
    Name = join("-", [var.name, "sg"])
  }
}

# resource "aws_security_group_rule" "all_in" {
#   type        = "ingress"
#   from_port   = 0
#   to_port     = 0
#   protocol    = "-1"
#   cidr_blocks = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.dsf_base_sg.id
# }

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

resource "aws_security_group_rule" "sg_self" {
  for_each          = local.ingress_ports_map
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sonarrsyslog_self" {
  type              = "ingress"
  from_port         = 10800
  to_port           = 10899
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_web_console_access" {
  count             = length(var.web_console_cidr) == 0 ? 0 : 1
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = var.web_console_cidr
  security_group_id = aws_security_group.dsf_base_sg.id
}

resource "aws_security_group_rule" "sg_allow_ssh_in_vpc" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.dsf_base_sg.id
}
