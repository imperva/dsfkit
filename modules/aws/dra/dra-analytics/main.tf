locals {
  incoming_folder_path = "/opt/itpba/incoming"

  public_ip  = aws_instance.dsf_base_instance.public_ip
  public_dns = aws_instance.dsf_base_instance.public_dns
  private_ip = length(aws_network_interface.eni.private_ips) > 0 ? tolist(aws_network_interface.eni.private_ips)[0] : null

  security_group_ids = concat(
    [aws_security_group.dsf_base_sg_out.id],
    [for sg in aws_security_group.dsf_base_sg_in : sg.id],
    var.security_group_ids
  )

  install_script = templatefile("${path.module}/setup.tftpl", {
    analytics_archiver_password_secret_arn    = aws_secretsmanager_secret.analytics_archiver_password.arn
    admin_analytics_registration_password_arn = aws_secretsmanager_secret.admin_analytics_registration_password.arn
    archiver_user                             = var.archiver_user
    archiver_password                         = var.archiver_password
    admin_server_private_ip                   = var.admin_server_private_ip
  })

  waiter_cmds_script = templatefile("${path.module}/waiter.tpl", {
    admin_server_public_ip  = var.admin_server_public_ip
  })
}

resource "aws_instance" "dsf_base_instance" {
  ami           = data.aws_ami.selected-ami.image_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_pair.ssh_public_key_name
  user_data     = local.install_script
  root_block_device {
    volume_size           = var.ebs.volume_size
    volume_type           = var.ebs.volume_type
    delete_on_termination = true
    tags                  = merge(var.tags, {Name = var.friendly_name})
  }
  iam_instance_profile = local.instance_profile
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  disable_api_termination     = true
  user_data_replace_on_change = true
  tags = merge(var.tags, {Name = var.friendly_name})
}

resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
  tags            = var.tags
}

resource "null_resource" "waiter_cmds" {
  provisioner "local-exec" {
    command     = local.waiter_cmds_script
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = [
    aws_instance.dsf_base_instance
  ]
}
