locals {
  disk_size_app        = 260
  ebs_state_disk_type  = "gp3"
  ebs_state_disk_size  = var.ebs == null ? null : var.ebs.disk_size
  ebs_state_iops       = var.ebs == null ? null : var.ebs.provisioned_iops
  ebs_state_throughput = var.ebs == null ? null : var.ebs.throughput

  install_script = templatefile("${path.module}/setup.tftpl", {
    admin_analytics_registration_password_secret_arn = aws_secretsmanager_secret.admin_analytics_registration_password_secret.arn
  })

  security_group_ids = concat(
    [aws_security_group.dsf_base_sg_out.id],
    [for sg in aws_security_group.dsf_base_sg_in : sg.id],
    var.security_group_ids
  )

  ami_name     = var.ami.name != null ? var.ami.name : "*"
  ami_id       = var.ami.id != null ? var.ami.id : "*"
  ami_owner_id = var.ami.owner_account_id != null ? var.ami.owner_account_id : "496834581024" # default is Imperva account id
}

data "aws_ami" "selected-ami" {
  most_recent = true
  owners      = [local.ami_owner_id]

  filter {
    name   = "image-id"
    values = [local.ami_id]
  }

  filter {
    name   = "name"
    values = [local.ami_name]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "dsf_base_instance" {
  ami           = data.aws_ami.selected-ami.image_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_pair.ssh_public_key_name
  user_data     = local.install_script
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

# Create a network interface for the instance
resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
}

resource "aws_eip" "dsf_instance_eip" {
  count = var.attach_public_ip ? 1 : 0
  vpc   = true
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.attach_public_ip ? 1 : 0
  instance_id   = aws_instance.dsf_base_instance.id
  allocation_id = aws_eip.dsf_instance_eip[0].id
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