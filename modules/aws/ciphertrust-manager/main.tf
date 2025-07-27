locals {
  web_console_username = "admin"

  security_group_ids = concat(
    [for sg in aws_security_group.sg : sg.id],
  var.security_group_ids)

  public_ip  = (var.attach_persistent_public_ip ?
    (length(aws_eip.dsf_instance_eip) > 0 ? aws_eip.dsf_instance_eip[0].public_ip : null) :
    aws_instance.cipthertrust_manager_instance.public_ip)
  public_dns = (var.attach_persistent_public_ip ?
    (length(aws_eip.dsf_instance_eip) > 0 ? aws_eip.dsf_instance_eip[0].public_dns : null) :
    aws_instance.cipthertrust_manager_instance.public_dns)
  private_ip = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null
}

resource "aws_eip" "dsf_instance_eip" {
  count  = var.attach_persistent_public_ip ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = var.friendly_name })
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.attach_persistent_public_ip ? 1 : 0
  instance_id   = aws_instance.cipthertrust_manager_instance.id
  allocation_id = aws_eip.dsf_instance_eip[0].id
}

resource "aws_instance" "cipthertrust_manager_instance" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair
  root_block_device {
    volume_size           = var.ebs.volume_size
    volume_type           = var.ebs.volume_type
    iops                  = var.ebs.iops
    delete_on_termination = true
  }
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  disable_api_termination = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags        = merge(var.tags, { Name : var.friendly_name })
  volume_tags = merge(var.tags, { Name : var.friendly_name })

  lifecycle {
    ignore_changes = [ami]
  }
  depends_on = [
    aws_network_interface.eni,
    aws_eip.dsf_instance_eip,
    data.aws_ami.selected-ami
  ]
}

resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
  tags            = var.tags
}