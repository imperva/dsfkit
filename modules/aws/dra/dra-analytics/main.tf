locals {
  security_group_ids = concat(
    [aws_security_group.dsf_base_sg_out.id],
    [for sg in aws_security_group.dsf_base_sg_in : sg.id],
    var.security_group_ids
  )

  ami_name     = var.ami.name != null ? var.ami.name : "*"
  ami_id       = var.ami.id != null ? var.ami.id : "*"
  ami_owner_id = var.ami.owner_account_id != null ? var.ami.owner_account_id : "496834581024" # default is Imperva account id

  install_script = templatefile("${path.module}/setup.tftpl", {
    analytics_archiver_password_secret_arn    = aws_secretsmanager_secret.analytics_archiver_password_secret.arn
    admin_analytics_registration_password_arn = var.admin_analytics_registration_password_arn
    archiver_user                             = var.archiver_user
    archiver_password                         = var.archiver_password
    admin_server_private_ip                   = var.admin_server_private_ip
  })

  waiter_cmds_script = templatefile("${path.module}/waiter.tpl", {
    admin_server_public_ip  = var.admin_server_public_ip
  })
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

resource "aws_instance" "dra_analytics" {
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
  iam_instance_profile = aws_iam_instance_profile.dsf_dra_analytics_instance_iam_profile.id
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  tags = merge(var.tags, {Name = var.friendly_name})
  disable_api_termination     = true
  user_data_replace_on_change = true
}

# Create a network interface for the analytics instance
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
    aws_instance.dra_analytics
  ]
}
