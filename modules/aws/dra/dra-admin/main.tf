locals {
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
    volume_size           = var.ebs.volume_size
    volume_type           = var.ebs.volume_type
    delete_on_termination = true
    tags                  = merge(var.tags, {Name = var.friendly_name})
  }
  iam_instance_profile = aws_iam_instance_profile.dsf_dra_admin_instance_iam_profile.id
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  disable_api_termination     = true
  user_data_replace_on_change = true
  tags = merge(var.tags, {Name = var.friendly_name})
}

# Create a network interface for the instance
resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
  tags            = var.tags
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
