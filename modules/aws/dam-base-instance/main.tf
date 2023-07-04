locals {
  public_ip  = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_ip : aws_instance.dsf_base_instance.public_ip
  public_dns = var.attach_persistent_public_ip ? aws_eip.dsf_instance_eip[0].public_dns : aws_instance.dsf_base_instance.public_dns
  private_ip = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null

  security_group_ids = concat(
    [for sg in aws_security_group.dsf_base_sg_in : sg.id],
  var.security_group_ids)

  secure_password           = var.secure_password
  mx_password               = var.mx_password
  encrypted_secure_password = chomp(aws_kms_ciphertext.encrypted_secure_password.ciphertext_blob)
  encrypted_mx_password     = chomp(aws_kms_ciphertext.encrypted_mx_password.ciphertext_blob)

  mapper = {
    instance_type = {
      AV2500 = "m4.xlarge",
      AV6500 = "r4.2xlarge",
      AVM150 = "m4.xlarge"
    }
    product_role = {
      mx       = "server",
      agent-gw = "gateway"
    }
  }
}

resource "aws_eip" "dsf_instance_eip" {
  count = var.attach_persistent_public_ip ? 1 : 0
  vpc   = true
  tags  = var.tags
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.attach_persistent_public_ip ? 1 : 0
  instance_id   = aws_instance.dsf_base_instance.id
  allocation_id = aws_eip.dsf_instance_eip[0].id
}

resource "aws_instance" "dsf_base_instance" {
  ami                  = data.aws_ami.selected-ami.image_id
  instance_type        = local.mapper.instance_type[var.dam_model]
  key_name             = var.key_pair
  user_data            = local.userdata
  iam_instance_profile = local.instance_profile
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  disable_api_termination     = true
  user_data_replace_on_change = true
  # metadata_options { # DAM still doesn't support IMDSv2
  #   http_endpoint = "enabled"
  #   http_tokens = "required"
  # }
  tags = merge(var.tags, { Name = var.name })
}

resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
  tags            = var.tags
}
