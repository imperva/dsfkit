locals {
  disk_size_app        = 100
  ebs_state_disk_type  = "gp3"
  ebs_state_iops       = 16000
  ebs_state_throughput = 1000
}

resource "aws_eip" "dsf_instance_eip" {
  count    = var.public_ip ? 1 : 0
  instance = aws_instance.dsf_base_instance.id
  vpc      = true
}

data "aws_ami" "redhat-7-ami" {
  most_recent = true
  owners      = ["309956199498"] # Amazon

  filter {
    name   = "name"
    values = ["RHEL-7.9*"]
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

#################################
# Hub cloudinit script (AKA userdata)
#################################

resource "aws_instance" "dsf_base_instance" {
  ami           = data.aws_ami.redhat-7-ami.image_id
  instance_type = var.ec2_instance_type
  key_name      = var.key_pair
  user_data     = templatefile("${path.module}/prepare_machine.tpl", {})
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
  disable_api_termination = true
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
  size              = var.ebs_state_disk_size
  type              = local.ebs_state_disk_type
  iops              = local.ebs_state_iops
  throughput        = local.ebs_state_throughput
  availability_zone = data.aws_subnet.selected_subnet.availability_zone
  tags = {
    Name = join("-", [var.name, "data", "volume", "ebs"])
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Create a network interface for DSF base instance
resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.dsf_base_sg.id]
}
