data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

locals {
  ports     = length(var.sg_web_console_cidr) > 0 ? [8083] : []
  ports_map = { for port in local.ports : port => port }
}

resource "aws_security_group" "dsf_web_console_sg" {
  description = "${var.friendly_name} - web console access"
  vpc_id      = data.aws_subnet.selected_subnet.vpc_id

  tags = {
    Name = join("-", [var.friendly_name, "web", "console"])
  }
}

resource "aws_security_group_rule" "dsf_web_console_rule" {
  for_each          = local.ports_map
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = var.sg_web_console_cidr
  security_group_id = aws_security_group.dsf_web_console_sg.id
}
