locals {
  disk_size_app        = 260
  ebs_state_disk_type  = "gp3"
  ebs_state_disk_size  = var.ebs == null ? null : var.ebs.disk_size
  ebs_state_iops       = var.ebs == null ? null : var.ebs.provisioned_iops
  ebs_state_throughput = var.ebs == null ? null : var.ebs.throughput
}

data "template_file" "admin_bootstrap" {
  template = file("${path.module}/admin_bootstrap.tpl")
  vars = {
    admin_analytics_registration_password_secret_arn = aws_secretsmanager_secret.admin_analytics_registration_password_secret.arn
  }
}

resource "aws_instance" "dra_admin" {
  ami           = var.admin_ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_pair.ssh_public_key_name
  user_data     = data.template_file.admin_bootstrap.rendered
  root_block_device {
    volume_size           = local.disk_size_app
    delete_on_termination = true
  }
  iam_instance_profile = aws_iam_instance_profile.dsf_dra_admin_instance_iam_profile.id
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

# Create a network interface for the admin instance
resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.admin-instance.id]
}

#data "aws_subnet" "selected_subnet" {
#  id = var.subnet_id
#}

# resource "aws_volume_attachment" "ebs_att" {
#   count = var.ebs == null ? 0 : 1
#   device_name                    = "/dev/sdb"
#   volume_id                      = aws_ebs_volume.ebs_external_data_vol[0].id
#   instance_id                    = aws_instance.dra_admin.id
#   stop_instance_before_detaching = true
# }

# resource "aws_ebs_volume" "ebs_external_data_vol" {
#   count = var.ebs == null ? 0 : 1
#   size              = local.ebs_state_disk_size
#   type              = local.ebs_state_disk_type
#   iops              = local.ebs_state_iops
#   throughput        = local.ebs_state_throughput
#   availability_zone = data.aws_subnet.selected_subnet.availability_zone
#   tags = {
#     Name = join("-", [var.deployment_name, "data", "volume", "ebs"])
#   }
#   lifecycle {
#     ignore_changes = [iops]
#   }
# }