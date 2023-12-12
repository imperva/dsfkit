locals {
  public_ip  = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_ip : aws_instance.dsf_base_instance.public_ip
  public_dns = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_dns : aws_instance.dsf_base_instance.public_dns
  private_ip = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null

  # root volume details
  root_volume_size = 100

  # state volume details
  ebs_state_disk_type  = "gp3"
  ebs_state_disk_size  = var.ebs_details.disk_size
  ebs_state_iops       = var.ebs_details.provisioned_iops
  ebs_state_throughput = var.ebs_details.throughput

  volume_attachment_device_name = var.volume_attachment_device_name == null ? "/dev/sdb" : var.volume_attachment_device_name

  security_group_ids = concat(
    [for sg in aws_security_group.dsf_base_sg : sg.id],
  var.security_group_ids)
}

resource "aws_eip" "dsf_instance_eip" {
  count  = var.attach_persistent_public_ip ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = var.name })
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.attach_persistent_public_ip ? 1 : 0
  instance_id   = aws_instance.dsf_base_instance.id
  allocation_id = aws_eip.dsf_instance_eip[0].id
}

resource "aws_instance" "dsf_base_instance" {
  ami           = data.aws_ami.selected-ami.image_id
  instance_type = var.ec2_instance_type
  key_name      = var.key_pair
  user_data     = local.install_script
  root_block_device {
    volume_size = local.root_volume_size
  }
  iam_instance_profile = local.instance_profile
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  disable_api_termination     = true
  user_data_replace_on_change = false
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags        = merge(var.tags, { Name = var.name })
  volume_tags = merge(var.tags, { Name = var.name })
}

resource "aws_volume_attachment" "ebs_att" {
  device_name                    = local.volume_attachment_device_name
  volume_id                      = aws_ebs_volume.ebs_external_data_vol.id
  instance_id                    = aws_instance.dsf_base_instance.id
  stop_instance_before_detaching = true
}

resource "aws_ebs_volume" "ebs_external_data_vol" {
  size              = local.ebs_state_disk_size
  type              = local.ebs_state_disk_type
  iops              = local.ebs_state_iops
  throughput        = local.ebs_state_throughput
  availability_zone = data.aws_subnet.selected_subnet.availability_zone
  tags              = merge(var.tags, { Name = join("-", [var.name, "data", "volume", "ebs"]) })
  lifecycle {
    ignore_changes = [iops]
  }
}

resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
  tags            = var.tags
}
