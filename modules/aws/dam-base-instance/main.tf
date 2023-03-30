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
# 24. disable root login
# 28. pass sg from outside
# 29. search and fix all tbd
# 30. compare with sonar modules

## tests:
# 1. matan's tests
# 20. test agent_listener_ssl

## validations
# 1. management_server_host. Should also support hostname - not just ipv4

## Things to verify with GW team
# 18. gw tells agent to send data to it's local ip rather than the one the agent registered with. Why? and how to fix it?
# 9. gw model - What models are there? Do we must use the imperva terms? Any reason we can use aws instance naming? what's the difference between AV6500 and AV2500? - https://www.imperva.com/resources/datasheets/Imperva_VirtualAppliances_V2.3_20220518.pdf
# 9. How to pick the mx instance type? should we limit the customer to what he can do?
# 17. what are the agent's ports 8030
# 11. secure password vs imperva/mx password
# 13. Can we attach external disks? Is that relevant for gw? where's all the state saved? (we wish to use external data disks). What does this do "/opt/SecureSphere/etc/ec2/create_audit_volume --volumesize=${local.VolumeSize}"
# 14. What marketplace brings to the table? that cloudformation doesnt? does market place uses cloudformation underneath? market place amis
# 15. How can we detect a failing environemnt? maybe through API?
# 16. katya about licensing
# 8. reduce iam policies to minimum

## Stratigic decisions
# 0. how would we manage the gigantic map of amis per region per version per environemnt. (this question is also relevant to sonar)
# 1. Should we limit the amis for marketplace?
# 2. Should we limit the ec2 type a customer can use?
# 2. What happens if something faild? What the customer should do? It should be obvious how to extract the failure? Poll a flag that tells us whether the installation succeeded?
# 25. allow an option to deploy without license?
