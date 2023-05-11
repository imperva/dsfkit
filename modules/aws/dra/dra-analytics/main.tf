locals {
  waiter_cmds_script = templatefile("${path.module}/waiter.tpl", {
    admin_server_public_ip  = var.admin_server_public_ip
  })
}

locals {
  disk_size_app        = 1010
  ebs_state_disk_type  = "gp3"
  ebs_state_disk_size  = var.ebs == null ? null : var.ebs.disk_size
  ebs_state_iops       = var.ebs == null ? null : var.ebs.provisioned_iops
  ebs_state_throughput = var.ebs == null ? null : var.ebs.throughput

  security_group_ids = concat(
    [aws_security_group.dsf_base_sg_out.id],
    [for sg in aws_security_group.dsf_base_sg_in : sg.id],
    var.security_group_ids
  )

  install_script = templatefile("${path.module}/setup.tftpl", {
    analytics_archiver_password_secret_arn    = aws_secretsmanager_secret.analytics_archiver_password_secret.arn
    admin_analytics_registration_password_arn = var.admin_analytics_registration_password_arn
    archiver_user                             = var.archiver_user
    archiver_password                         = var.archiver_password
    admin_server_private_ip                   = var.admin_server_private_ip
  })
}

resource "aws_instance" "dra_analytics" {
  ami           = var.analytics_ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_pair.ssh_public_key_name
  user_data     = local.install_script
  root_block_device {
    volume_size           = local.disk_size_app
    delete_on_termination = true
  }
  iam_instance_profile = aws_iam_instance_profile.dsf_dra_analytics_instance_iam_profile.id
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  tags = {
     Name = var.friendly_name
  }
  disable_api_termination     = true
  user_data_replace_on_change = true
}

# Create a network interface for the analytics instance
resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
}

resource "null_resource" "waiter_cmds" {
  provisioner "local-exec" {
    command     = local.waiter_cmds_script
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    aws_instance.dra_analytics
  ]
}

data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

resource "aws_volume_attachment" "ebs_att" {
  count                          = var.ebs == null ? 0 : 1
  device_name                    = "/dev/sdb"
  volume_id                      = aws_ebs_volume.ebs_external_data_vol[0].id
  instance_id                    = aws_instance.dra_analytics.id
  stop_instance_before_detaching = true
}

resource "aws_ebs_volume" "ebs_external_data_vol" {
  count             = var.ebs == null ? 0 : 1
  size              = local.ebs_state_disk_size
  type              = local.ebs_state_disk_type
  iops              = local.ebs_state_iops
  throughput        = local.ebs_state_throughput
  availability_zone = data.aws_subnet.selected_subnet.availability_zone
  tags = {
    Name = join("-", [var.friendly_name, "data", "volume", "ebs"])
  }
  lifecycle {
    ignore_changes = [iops]
  }
}
