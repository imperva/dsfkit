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
    af-south-1 = {
      ImageId = "ami-079e3d30c3074147d"
    }
    ap-east-1 = {
      ImageId = "ami-03ac6c9504dc26ac2"
    }
    ap-northeast-1 = {
      ImageId = "ami-001c5dba9b08e1e20"
    }
    ap-northeast-2 = {
      ImageId = "ami-08b9cdffbc03dee8b"
    }
    ap-northeast-3 = {
      ImageId = "ami-0f1e40e7e8e549a58"
    }
    ap-south-1 = {
      ImageId = "ami-02c40d18eb669ff26"
    }
    ap-southeast-1 = {
      ImageId = "ami-06e7bef08cdc49198"
    }
    ap-southeast-2 = {
      ImageId = "ami-05ef3406d6e34b6da"
    }
    ca-central-1 = {
      ImageId = "ami-053e90b658d30bc99"
    }
    eu-central-1 = {
      ImageId = "ami-0b89ffcd9a860992b"
    }
    eu-north-1 = {
      ImageId = "ami-0329f6538d2e8180d"
    }
    eu-west-1 = {
      ImageId = "ami-0490ed56f9a4fbc77"
    }
    eu-west-2 = {
      ImageId = "ami-0f2c96ca38d80ff73"
    }
    eu-west-3 = {
      ImageId = "ami-0c6a9375caa74fa76"
    }
    sa-east-1 = {
      ImageId = "ami-0bc7e775cb2d5ec2f"
    }
    us-east-1 = {
      ImageId = "ami-019af5343736a400e"
    }
    us-east-2 = {
      ImageId = "ami-046e98684e13345cd"
    }
    us-gov-east-1 = {
      ImageId = "ami-0220487b63f39463d"
    }
    us-gov-west-1 = {
      ImageId = "ami-036febe3bded78c9a"
    }
    us-west-1 = {
      ImageId = "ami-060d440817f97f6a5"
    }
    us-west-2 = {
      ImageId = "ami-0d3d795b13aa624f9"
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
