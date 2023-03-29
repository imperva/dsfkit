locals {
  security_group_ids = concat(
    [aws_security_group.dsf_base_sg.id],
    [aws_security_group.dsf_ssh_sg.id],
  [aws_security_group.dsf_web_console_sg.id])

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

# tbd: we can't enforce usage of images from market place
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

# tbd: questions
# 0. how would we manage the gigantic map of amis per region per version per environemnt. (this question is also relevant to sonar)
# 1. Should we limit the amis for marketplace?
# 2. Should we limit the ec2 type a customer can use?
# 2. What happens if something faild? What the customer should do? It should be obvious how to extract the failure? Poll a flag that tells us whether the installation succeeded?
# 4. Add some kind of predeployment MPRV file validation
# 17. add description too all variables
# 18. remove uneeded variables
# 20. test agent_listener_ssl
# 24. disable root login
# 25. allow an option to deploy without license?
# 26. add validation to all variables (management_server_host)
# 28. pass sg from outside
# 29. search and fix all tbd
# 30. add many preconditions all over

## Things to verify with GW team
# 8. reduce iam policies to minimum
# 9. gw model - What models are there? Do we must use the imperva terms? Any reason we can use aws instance naming? what's the difference between AV6500 and AV2500? - https://www.imperva.com/resources/datasheets/Imperva_VirtualAppliances_V2.3_20220518.pdf
# 9. How to pick the mx instance type? should we limit the customer to what he can do?
# 10. What's the constraints for a password - "2023-03-28_18:11:58: Setting system password for db. Function - configure_system_user_password. Error -  Invalid password (exit status: 7)."
# 11. secure password vs imperva/mx password
# 12. allow 2 password per gw/mx module
# 13. Can we attach external disks? Is that relevant for gw? where's all the state saved? (we wish to use external data disks). What does this do "/opt/SecureSphere/etc/ec2/create_audit_volume --volumesize=${local.VolumeSize}"
# 14. What marketplace brings to the table? that cloudformation doesnt? does market place uses cloudformation underneath?
# 15. How can we detect a failing environemnt? maybe through API?
# 16. katya about licensing
# 17. what are the agent's ports