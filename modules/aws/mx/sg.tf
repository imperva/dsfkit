data "aws_subnet" "subnet" {
  id = var.subnet_id
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.selected_subnet.vpc_id
}

locals {
  cidr_blocks       = var.sg_ingress_cidr
  ingress_ports     = [22, 443, 514, 2812, 8081, 8083, 8084, 8085]
  ingress_ports_map = { for port in local.ingress_ports : port => port }
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

# resource "aws_security_group_rule" "sg_self" {
#   for_each          = local.ingress_ports_map
#   type              = "ingress"
#   from_port         = each.value
#   to_port           = each.value
#   protocol          = "tcp"
#   self              = true
#   security_group_id = aws_security_group.dsf_base_sg.id
# }

# resource "aws_security_group_rule" "sg_ingress_self" {
#   type              = "ingress"
#   from_port         = 0
#   to_port           = 65535
#   protocol          = "tcp"
#   self              = true
#   security_group_id = aws_security_group.dsf_base_sg.id
# }

resource "aws_security_group_rule" "sg_web_console_access" {
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

# resource "aws_security_group_rule" "sg_allow_all_ssh" {
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.dsf_base_sg.id
# }
