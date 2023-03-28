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

  secure_password           = var.secure_password
  mx_password               = var.imperva_password
  encrypted_secure_password = chomp(aws_kms_ciphertext.encrypted_secure_password.ciphertext_blob)
  encrypted_mx_password     = chomp(aws_kms_ciphertext.encrypted_mx_password.ciphertext_blob)

  timezone = "UTC"

  VolumeSize = "500"

  

  # mapper = {
  #   mx = {
  #     "product": "dammxbyol"
  #   },
  #   agent-gw = {
  #     "product": "damgwbyol"
  #   }
  # }

  # GW
  instance_type = {
    AV2500 = "m4.xlarge",
    AV6500 = "r4.2xlarge",
    AVM150 = "m4.xlarge"
  }

  # MX
  # instance_type = {
  #   c5.xlarge
  # }
}

resource "random_uuid" "gw_group" {}

data "aws_region" "current" {}

locals {
  dammxbyolRegion2Ami = {
    us-east-1 = {
      ImageId = "ami-019af5343736a400e"
    }
    us-east-2 = {
      ImageId = "ami-046e98684e13345cd"
    }
  }
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

# we can't enforce usage of images from market place
data "aws_ami" "selected-ami" {
  owners = ["aws-marketplace"]

  filter {
    name   = "image-id"
    values = [lookup(local.dammxbyolRegion2Ami[data.aws_region.current.name], "ImageId")]
  }
}

resource "aws_instance" "dsf_base_instance" {
  ami           = data.aws_ami.selected-ami.image_id
  instance_type = local.instance_type[var.ses_model]
  key_name      = var.key_pair
  user_data = local.userdata
  # root_block_device {
  #   volume_size = local.disk_size_app
  # }
  #should we enable the customer to enlarge the disk?
  iam_instance_profile = aws_iam_instance_profile.dsf_node_instance_iam_profile.id
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

# tbd: questions
# 0. how would we manage the gigantic map of amis per region per version per environemnt. (this question is also relevant to sonar)
# 1. Should we limit the amis for marketplace?
# 2. Should we limit the ec2 type a customer can use?
# 3. how do we want to encrypt the dam license?
# 4. Add some kind of predeployment MPRV file validation
# 5. volume attachement?
# 6. sg
# 7. Poll a flag that tells us whether the installation succeeded
# 8. reduce iam policies to minimum
# 9. gw model - how imporant is it?
# 10. check volume size (VolumeSize) (/opt/SecureSphere/etc/ec2/create_audit_volume)
# 11. apply after apply (make sure it doesn't destroy both mx and gw)
# 12. should we use "--waitForServer"" gw arg
# 13. split secure pass and imperva pass 
# 14. add post test to licence encryption
# 15. what's the difference between AV6500 and AV2500
# 16. add precondition for gw_group_id when deploying gw
# 17. add description too all variables
# 18. remove uneeded variables
# 19. use external data disks
# 20. check agent_listener_ssl
# 21. considering removal of management_server_host var
# 22. add pre condition for mx license