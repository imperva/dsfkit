locals {
  db_types = ["PostgreSql", "MySql", "MariaDB"]
  os_types = keys(local.os_params)

  db_type           = var.db_type != null ? var.db_type : random_shuffle.db.result[0]
  os_type           = var.os_type != null ? var.os_type : random_shuffle.os.result[0]
  binaries_location = var.binaries_location != null ? var.binaries_location : local.os_params[local.os_type].binaries_location
}

resource "random_shuffle" "db" {
  input = local.db_types
}

resource "random_shuffle" "os" {
  input = local.os_types
}

resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = concat(var.security_group_ids, [aws_security_group.dsf_agent_sg.id])
}

resource "aws_instance" "agent" {
  ami           = data.aws_ami.selected-ami.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  iam_instance_profile        = aws_iam_instance_profile.dsf_node_instance_iam_profile.id
  user_data                   = local.user_data
  user_data_replace_on_change = true
  tags = {
    Name = join("-", [var.friendly_name])
  }
}
