locals {
  # disk_size_app        = 100
  # ebs_state_disk_type  = "gp3"
  # ebs_state_disk_size  = var.ebs_details.disk_size
  # ebs_state_iops       = var.ebs_details.provisioned_iops
  # ebs_state_throughput = var.ebs_details.throughput

  security_group_id = aws_security_group.dsf_base_sg.id

  # ami
  # ami_default = {
  #   id               = null
  #   owner_account_id = "309956199498"
  #   username         = "ec2-user"
  #   name             = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2"
  # }

  # ami = var.ami != null ? var.ami : local.ami_default

  # ami_owner    = local.ami.owner_account_id != null ? local.ami.owner_account_id : "self"
  # ami_name     = local.ami.name != null ? local.ami.name : "*"
  # ami_id       = local.ami.id != null ? local.ami.id : "*"
  ami_username = "ec2-user"
}

resource "aws_eip" "dsf_instance_eip" {
  count = var.attach_pubilc_ip ? 1 : 0
  vpc   = true
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.attach_pubilc_ip ? 1 : 0
  instance_id   = aws_instance.dsf_base_instance.id
  allocation_id = aws_eip.dsf_instance_eip[0].id
}

data "aws_ami" "selected-ami" {
  most_recent = true
  # owners      = [local.ami_owner]

  filter {
    name   = "image-id"
    values = [var.ami]
  }
}

data local_file userdata {
  filename = "${path.module}/1.sh"
}

resource "aws_instance" "dsf_base_instance" {
  ami           = data.aws_ami.selected-ami.image_id
  instance_type = var.ec2_instance_type
  key_name      = var.key_pair
  user_data     = data.local_file.userdata.content
  # user_data     = local.install_script
  # root_block_device {
  #   volume_size = local.disk_size_app
  # }
  #should we enable the customer to enlarge the disk?
  # iam_instance_profile = aws_iam_instance_profile.dsf_node_instance_iam_profile.id
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

# resource "aws_volume_attachment" "ebs_att" {
#   device_name                    = "/dev/sdb"
#   volume_id                      = aws_ebs_volume.ebs_external_data_vol.id
#   instance_id                    = aws_instance.dsf_base_instance.id
#   stop_instance_before_detaching = true
# }

# resource "aws_ebs_volume" "ebs_external_data_vol" {
#   size              = local.ebs_state_disk_size
#   type              = local.ebs_state_disk_type
#   iops              = local.ebs_state_iops
#   throughput        = local.ebs_state_throughput
#   availability_zone = data.aws_subnet.selected_subnet.availability_zone
#   tags = {
#     Name = join("-", [var.name, "data", "volume", "ebs"])
#   }
#   lifecycle {
#     ignore_changes = [iops]
#   }
# }

# Create a network interface for DSF base instance
resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = [local.security_group_id]
}
