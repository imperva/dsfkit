resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = concat(var.security_group_ids, [aws_security_group.dsf_agent_sg.id])
}

resource "aws_instance" "agent" {
  ami           = local.ami
  instance_type = "t2.micro"
  key_name      = var.key_pair
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  user_data = local.user_data
  user_data_replace_on_change = true
  tags = {
    Name = join("-", [var.friendly_name, "db", "with", "agent"])
  }
}
