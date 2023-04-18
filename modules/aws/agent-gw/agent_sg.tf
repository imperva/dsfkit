data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

locals {
  ports     = length(var.sg_agent_cidr) > 0 ? [443, var.agent_listener_port] : []
  ports_map = { for port in local.ports : port => port }
}

resource "aws_security_group" "dsf_agent_sg" {
  description = "${var.friendly_name} - agent access"
  vpc_id      = data.aws_subnet.selected_subnet.vpc_id

  tags = {
    Name = join("-", [var.friendly_name, "agent", "sg"])
  }
}

resource "aws_security_group_rule" "dsf_agent_rule" {
  for_each          = local.ports_map
  type              = "ingress"
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
  cidr_blocks       = var.sg_agent_cidr
  security_group_id = aws_security_group.dsf_agent_sg.id
}
