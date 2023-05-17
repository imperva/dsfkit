data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.selected_subnet.vpc_id
}

resource "aws_security_group" "dsf_agent_sg" {
  description = "${var.friendly_name} - Basic security group"
  vpc_id      = data.aws_subnet.selected_subnet.vpc_id
  tags = var.tags
}

resource "aws_security_group_rule" "all_out" {
  description       = "${var.friendly_name} - Allow all out"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dsf_agent_sg.id
}

resource "aws_security_group_rule" "sg_cidr_ingress" {
  description       = "${var.friendly_name} - Allow ssh local"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = concat([data.aws_vpc.selected.cidr_block], var.allowed_ssh_cidrs)
  security_group_id = aws_security_group.dsf_agent_sg.id
}
