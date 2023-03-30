locals {
  security_group_ids = concat(
    [aws_security_group.dsf_base_sg.id],
  [aws_security_group.dsf_ssh_sg.id])

  secure_password           = var.secure_password
  mx_password               = var.imperva_password
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

data "aws_ami" "selected-ami" {
  owners = ["aws-marketplace"]

  filter {
    name   = "image-id"
    values = [lookup(local.dammxbyolRegion2Ami[data.aws_region.current.name], "ImageId")]
  }
}

resource "aws_instance" "dsf_base_instance" {
  ami                  = data.aws_ami.selected-ami.image_id
  instance_type        = local.mapper.instance_type[var.ses_model]
  key_name             = var.key_pair
  user_data            = local.userdata
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

  lifecycle {
    # precondition {
    #   condition     = var.resource_type == "agent-gw" || var.resource_type == "mx" && var.encrypted_license == null
    #   error_message = "MX provisioning requires a license"
    # }
    # precondition {
    #   condition     = var.resource_type == "mx" || var.resource_type == "agent-gw" && var.management_server_host != null
    #   error_message = "GW provisioning requires an MX to register to"
    # }
  }
}

# Attach an additional storage device to DSF base instance
data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

# Create a network interface for DSF base instance
resource "aws_network_interface" "eni" {
  subnet_id       = var.subnet_id
  security_groups = local.security_group_ids
}

# questions
# 25. remove gw public ip assignment
# 28. pass sg from outside
# 30. compare with sonar modules

## tests:
# 1. matan's tests - nat ip - yotam
# 20. test agent_listener_ssl

## Things to verify with GW team
# 11. secure password vs imperva/mx password. Ariel bresler.
# 16. katya about licensing

## bugs:
# 1. creating multiple (happened twice with 3) gw concurrenrly results a failure - Cannot connect to 10.0.101.100:8083 [HTTP: 450 APP: response code is 450. CANNOT_ACQUIRE_LOCK] (exit status: 100)

## Stratigic decisions
# 15. How can we detect a failing environemnt? maybe through API? How to get the failure (print command to get the failure)
# 1. ses model
# GW MODEL - should we allow the user to pick ec2 instance type?
# MX MODEL - should we allow the user to pick ec2 instance type? Probably yes (as cloudformation allows him to pick 1)
# 2. external disks:
# Can we attach external disks? Is that relevant for gw? where's all the state saved? (we wish to use external data disks). What does this do "/opt/SecureSphere/etc/ec2/create_audit_volume --volumesize=${local.VolumeSize}"
# 3. amis
# Permissions
# how would we manage the gigantic map of amis per region per version per environemnt. (this question is also relevant to sonar)  # market place
# What marketplace brings to the table? that cloudformation doesnt? does market place uses cloudformation underneath? market place amis - or yesharim
# Should we limit the amis for marketplace?
# 4. iam roles
# reduce to minimum
# 5. allow an option to deploy without license?
