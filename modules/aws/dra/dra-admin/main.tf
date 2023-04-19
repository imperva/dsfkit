locals {
  disk_size_app        = 100
  ebs_state_disk_type  = "gp3"
  ebs_state_disk_size  = var.ebs.disk_size
  ebs_state_iops       = var.ebs.provisioned_iops
  ebs_state_throughput = var.ebs.throughput
}



data "template_file" "admin_bootstrap" {
  template = file("${path.module}/admin_bootstrap.tpl")
  vars = {
    admin_analytics_registration_password = var.admin_analytics_registration_password
  }
}
resource "aws_instance" "dra_admin" {
  ami           = var.admin_ami_id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = ["${aws_security_group.admin-server-demo.id}"]
  key_name = var.ssh_key_pair.ssh_public_key_name
  user_data = data.template_file.admin_bootstrap.rendered
  tags = {
    Name = var.deployment_name
  }
}

data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

resource "aws_volume_attachment" "ebs_att" {
  device_name                    = "/dev/sdb"
  volume_id                      = aws_ebs_volume.ebs_external_data_vol.id
  instance_id                    = aws_instance.dra_admin.id
  stop_instance_before_detaching = true
}

resource "aws_ebs_volume" "ebs_external_data_vol" {
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