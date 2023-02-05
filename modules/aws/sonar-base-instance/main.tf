locals {
  disk_size_app        = 100
  ebs_state_disk_type  = "gp3"
  ebs_state_disk_size  = var.ebs_details.disk_size
  ebs_state_iops       = var.ebs_details.provisioned_iops
  ebs_state_throughput = var.ebs_details.throughput

  ami_name_default = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2" # Exists on all regions
  ami_name         = var.ami_name_tag != null ? var.ami_name_tag : local.ami_name_default
  ami_user_default = "ec2-user"
  ami_user         = var.ami_user != null ? var.ami_user : local.ami_user_default

  security_group_id = length(aws_security_group.dsf_base_sg) > 0 ? element(aws_security_group.dsf_base_sg.*.id, 0) : var.security_group_id
}

resource "aws_eip" "dsf_instance_eip" {
  count    = var.create_and_attach_public_elastic_ip ? 1 : 0
  instance = aws_instance.dsf_base_instance.id
  vpc      = true
}

data "aws_ami" "redhat-7-ami" {
  most_recent = true
  owners      = ["309956199498"] # Amazon

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
  ami           = data.aws_ami.redhat-7-ami.image_id
  instance_type = var.ec2_instance_type
  key_name      = var.key_pair
  user_data     = local.install_script
  root_block_device {
    volume_size = local.disk_size_app
  }
  iam_instance_profile = var.iam_instance_profile_id
  network_interface {
    network_interface_id = aws_network_interface.eni.id
    device_index         = 0
  }
  tags = {
    Name = var.name
  }
  disable_api_termination     = true
  user_data_replace_on_change = true
}

# Attach an additional storage device to DSF base instance
data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

resource "aws_volume_attachment" "ebs_att" {
  device_name                    = "/dev/sdb"
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
  tags = {
    Name = join("-", [var.name, "data", "volume", "ebs"])
  }
  lifecycle {
    ignore_changes = [iops]
  }
}

# Create a network interface for DSF base instance
resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = [local.security_group_id]
}
