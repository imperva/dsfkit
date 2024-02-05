locals {
  db_types = ["PostgreSql", "MySql", "MariaDB"]
  os_types = keys(local.os_params)

  db_type           = var.db_type != null ? var.db_type : random_shuffle.db.result[0]
  os_type           = var.os_type != null ? var.os_type : random_shuffle.os.result[0]

  installation_s3_object            = var.binaries_location.s3_object != null ? var.binaries_location.s3_object : local.os_params[local.os_type].installation_filename
  installation_s3_key               = var.binaries_location.s3_prefix != null ? join("/", [var.binaries_location.s3_prefix, local.installation_s3_object]) : local.installation_s3_object
  installation_s3_bucket_and_prefix = var.binaries_location.s3_prefix != null ? join("/", [var.binaries_location.s3_bucket, var.binaries_location.s3_prefix]) : var.binaries_location.s3_bucket
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
  tags            = var.tags
}

resource "aws_instance" "agent" {
  ami           = data.aws_ami.selected-ami.id
  instance_type = "t2.micro"
  key_name      = var.key_pair
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  iam_instance_profile = aws_iam_instance_profile.dsf_node_instance_iam_profile.id
  user_data            = local.user_data
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = merge(var.tags, { Name = join("-", [var.friendly_name]) })
}
