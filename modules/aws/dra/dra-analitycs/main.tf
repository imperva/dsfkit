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
}

data "template_file" "analytics_bootstrap" {
  template = file("${path.module}/analytics_bootstrap.tpl")
  vars = {
    admin_analytics_registration_password = var.admin_analytics_registration_password
    archiver_user = var.archiver_user
    archiver_password = var.archiver_password
    admin_server_private_ip = var.admin_server_private_ip
  }
}
resource "aws_instance" "dra_analytics" {
  ami           = var.analytics_ami_id
  root_block_device {
    delete_on_termination = true
    volume_size = local.disk_size_app
  }
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = ["${aws_security_group.analytics-instance.id}"]
  key_name = var.ssh_key_pair.ssh_public_key_name
  user_data = data.template_file.analytics_bootstrap.rendered
  tags = {
     Name = join("-", [var.deployment_name, "analytics"])
  }
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
  count = var.ebs == null ? 0 : 1
  device_name                    = "/dev/sdb"
  volume_id                      = aws_ebs_volume.ebs_external_data_vol[0].id
  instance_id                    = aws_instance.dra_analytics.id
  stop_instance_before_detaching = true
}

resource "aws_ebs_volume" "ebs_external_data_vol" {
  count = var.ebs == null ? 0 : 1
  size              = local.ebs_state_disk_size
  type              = local.ebs_state_disk_type
  iops              = local.ebs_state_iops
  throughput        = local.ebs_state_throughput
  availability_zone = data.aws_subnet.selected_subnet.availability_zone
  tags = {
    Name = join("-", [var.deployment_name, "data", "volume", "ebs"])
  }
  lifecycle {
    ignore_changes = [iops]
  }
}
